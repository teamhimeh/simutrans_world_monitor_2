import Foundation

/// Mock implementation of SimutransInterface for testing
struct MockSimutransInterface {
    /// Mock file I/O
    private let mockFileIO: MockSimutransFileIO
    
    /// Input file path
    let inputFilePath: String
    
    /// Output file path
    let outputFilePath: String
    
    /// Timeout
    let timeout: TimeInterval
    
    /// Callback to be executed when sendData is called
    var onSendData: ((Data) -> Data)?
    
    /// Initializes a new mock Simutrans interface
    /// - Parameters:
    ///   - mockFileIO: The mock file I/O to use
    ///   - inputFilePath: The input file path
    ///   - outputFilePath: The output file path
    ///   - timeout: The timeout
    init(
        mockFileIO: MockSimutransFileIO,
        inputFilePath: String = "mock_input.json",
        outputFilePath: String = "mock_output.json",
        timeout: TimeInterval = 1.0
    ) {
        self.mockFileIO = mockFileIO
        self.inputFilePath = inputFilePath
        self.outputFilePath = outputFilePath
        self.timeout = timeout
    }
    
    /// Sends data to the mock Simutrans
    /// - Parameter data: The data to send
    /// - Returns: The response data
    /// - Throws: SimutransError if there's an error
    func sendData(_ data: Data) async throws -> Data {
        // Call the callback if it exists
        if let onSendData = onSendData {
            return onSendData(data)
        }
        
        // Extract the command ID from the input data
        let commandId = try extractCommandId(from: data)
        
        // Otherwise, use the mock file I/O
        // Wait until the input file is empty (Simutrans has processed previous commands)
        while !(try await mockFileIO.isFileEmpty(inputFilePath)) {
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        // Write the data to the input file
        try await mockFileIO.writeData(data, to: inputFilePath)
        
        // Read the response from the output file with ID verification
        return try await readResponseWithIdVerification(commandId: commandId)
    }
    
    /// Extracts the command ID from the input data
    /// - Parameter data: The input data
    /// - Returns: The command ID
    /// - Throws: SimutransError if the ID cannot be extracted
    private func extractCommandId(from data: Data) throws -> String {
        do {
            // Try to parse the JSON to extract the ID
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let id = json["id"] as? String {
                return id
            }
            throw SimutransError.jsonParsingError("Failed to extract command ID from input data")
        } catch {
            throw SimutransError.jsonParsingError("Failed to parse input JSON: \(error.localizedDescription)")
        }
    }
    
    /// Reads the response from the output file, verifying that the ID matches the expected command ID
    /// - Parameter commandId: The expected command ID
    /// - Returns: The response data
    /// - Throws: SimutransError if there's an error or timeout
    private func readResponseWithIdVerification(commandId: String) async throws -> Data {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            do {
                // Read the output file
                let outputData = try await mockFileIO.readData(from: outputFilePath, timeout: timeout)
                
                // If the file is empty, wait and retry
                if outputData.isEmpty {
                    try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                    continue
                }
                
                // Try to parse the JSON to extract the ID
                if let json = try? JSONSerialization.jsonObject(with: outputData) as? [String: Any],
                   let responseId = json["id"] as? String {
                    
                    // Check if the ID matches
                    if responseId == commandId {
                        return outputData
                    }
                    
                    // If the ID doesn't match, wait and retry
                    try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                    continue
                }
                
                // If we couldn't parse the JSON or extract the ID, wait and retry
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            } catch {
                // If there was an error reading the file, wait and retry
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
        }
        
        throw SimutransError.commandTimeout
    }
    
    /// Sets up the mock to return a specific response for a player list command
    /// - Parameter players: The players to include in the response
    /// - Returns: The command ID
    @discardableResult
    func setupMockPlayerListResponse(players: [PlayerListResponse.Player]) async throws -> String {
        // Create a random command ID
        let commandId = UUID().uuidString
        
        // Create the response
        let response = PlayerListResponse(
            command: "get_player_list",
            id: commandId,
            result: players
        )
        
        // Encode the response
        let encoder = JSONEncoder()
        let responseData = try encoder.encode(response)
        
        // Set the output file data
        await mockFileIO.setOutputFileData(responseData)
        
        return commandId
    }
    
    /// Sets up the mock to return a specific response for a lines command
    /// - Parameters:
    ///   - lines: The lines to include in the response
    ///   - commandId: The command ID to use, or nil to generate a random one
    /// - Returns: The command ID
    @discardableResult
    func setupMockLinesResponse(lines: [LinesResponse.Line], commandId: String? = nil) async throws -> String {
        // Use the provided command ID or generate a random one
        let commandId = commandId ?? UUID().uuidString
        
        // Create the response
        let response = LinesResponse(
            command: "get_lines",
            id: commandId,
            result: lines
        )
        
        // Encode the response
        let encoder = JSONEncoder()
        let responseData = try encoder.encode(response)
        
        // Set the output file data
        await mockFileIO.setOutputFileData(responseData)
        
        return commandId
    }
    
    /// Sets up the mock to return an error response
    /// - Parameters:
    ///   - description: The error description
    ///   - commandId: The command ID to use, or nil to generate a random one
    /// - Returns: The command ID
    @discardableResult
    func setupMockErrorResponse(description: String, commandId: String? = nil) async throws -> String {
        // Use the provided command ID or generate a random one
        let commandId = commandId ?? UUID().uuidString
        
        // Create the response
        let response = ErrorResponse(
            id: commandId,
            description: description
        )
        
        // Encode the response
        let encoder = JSONEncoder()
        let responseData = try encoder.encode(response)
        
        // Set the output file data
        await mockFileIO.setOutputFileData(responseData)
        
        return commandId
    }
}

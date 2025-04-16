import Foundation

/// Interface for communicating with Simutrans
struct SimutransInterface: Sendable {
    private let fileIO: any SimutransFileIOProtocol
    
    let inputFilePath: String
    let outputFilePath: String
    let timeout: TimeInterval
    
    init(fileIO: any SimutransFileIOProtocol, inputFilePath: String, outputFilePath: String, timeout: TimeInterval = 15.0) {
        self.fileIO = fileIO
        self.inputFilePath = inputFilePath
        self.outputFilePath = outputFilePath
        self.timeout = timeout
    }
    
    /// Sends data to Simutrans and waits for a response
    /// - Parameter data: The data to send
    /// - Returns: The response data
    /// - Throws: SimutransError if there's an error
    func sendData(_ data: Data) async throws -> Data {
        // Extract the command ID from the input data
        let commandId = try extractCommandId(from: data)
        
        // Wait until the input file is empty (Simutrans has processed previous commands)
        while !(try await fileIO.isFileEmpty(inputFilePath)) {
            try await Task.sleep(nanoseconds: 500_000_000) // 500ms
        }
        
        // Write the data to the input file
        try await fileIO.writeData(data, to: inputFilePath)
        
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
                let outputData = try await fileIO.readData(from: outputFilePath, timeout: timeout)
                
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
}

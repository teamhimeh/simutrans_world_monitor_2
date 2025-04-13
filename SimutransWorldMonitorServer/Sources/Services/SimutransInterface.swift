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
        // Wait until the input file is empty (Simutrans has processed previous commands)
        while !(try await fileIO.isFileEmpty(inputFilePath)) {
            try await Task.sleep(nanoseconds: 500_000_000) // 500ms
        }
        
        // Write the data to the input file
        try await fileIO.writeData(data, to: inputFilePath)
        
        // Read the response from the output file
        return try await fileIO.readData(from: outputFilePath, timeout: timeout)
    }
}

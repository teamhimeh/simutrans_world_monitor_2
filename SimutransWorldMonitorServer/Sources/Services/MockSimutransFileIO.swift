import Foundation

/// Mock implementation of SimutransFileIOProtocol for testing
actor MockSimutransFileIO: SimutransFileIOProtocol {
    /// Stored data for the mock input file
    private var inputFileData: Data = Data()
    
    /// Stored data for the mock output file
    private var outputFileData: Data = Data()
    
    /// Callback to be executed when writeData is called
    var onWriteData: ((Data, String) -> Void)?
    
    /// Callback to be executed when readData is called
    var onReadData: ((String, TimeInterval) -> Data)?
    
    /// Callback to be executed when isFileEmpty is called
    var onIsFileEmpty: ((String) -> Bool)?
    
    /// Delay to simulate file I/O operations
    var simulatedDelay: TimeInterval = 0.1
    
    func writeData(_ data: Data, to filePath: String) async throws {
        // Call the callback if it exists
        onWriteData?(data, filePath)
        
        // Simulate delay
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }
        
        // Store the data
        inputFileData = data
    }
    
    func readData(from filePath: String, timeout: TimeInterval) async throws -> Data {
        // Call the callback if it exists
        if let onReadData = onReadData {
            return onReadData(filePath, timeout)
        }
        
        // Simulate delay
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }
        
        // Return the stored output data
        return outputFileData
    }
    
    func isFileEmpty(_ filePath: String) async throws -> Bool {
        // Call the callback if it exists
        if let onIsFileEmpty = onIsFileEmpty {
            return onIsFileEmpty(filePath)
        }
        
        // Simulate delay
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }
        
        // Check if the input file data is empty
        return inputFileData.isEmpty
    }
    
    /// Sets the data that will be returned when readData is called
    /// - Parameter data: The data to return
    func setOutputFileData(_ data: Data) {
        outputFileData = data
    }
    
    /// Clears the input file data
    func clearInputFile() {
        inputFileData = Data()
    }
    
    /// Gets the current input file data
    /// - Returns: The current input file data
    func getInputFileData() -> Data {
        return inputFileData
    }
}

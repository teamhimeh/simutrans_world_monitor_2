import Foundation

/// Protocol defining the low-level interface for file I/O with Simutrans
protocol SimutransFileIOProtocol: Sendable {
    /// Writes data to the input file
    /// - Parameters:
    ///   - data: The data to write
    ///   - filePath: The path to the input file
    /// - Throws: Error if writing fails
    func writeData(_ data: Data, to filePath: String) async throws
    
    /// Reads data from the output file
    /// - Parameters:
    ///   - filePath: The path to the output file
    ///   - timeout: The maximum time to wait for a response
    /// - Returns: The response data
    /// - Throws: Error if reading fails or times out
    func readData(from filePath: String, timeout: TimeInterval) async throws -> Data
    
    /// Checks if the input file is empty (ready for a new command)
    /// - Parameter filePath: The path to the input file
    /// - Returns: True if the file is empty, false otherwise
    /// - Throws: Error if checking fails
    func isFileEmpty(_ filePath: String) async throws -> Bool
}

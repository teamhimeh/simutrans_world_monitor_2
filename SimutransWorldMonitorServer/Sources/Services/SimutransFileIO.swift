import Foundation

/// Implementation of SimutransFileIOProtocol for real file I/O
actor SimutransFileIO: SimutransFileIOProtocol {
    private let fileManager = FileManager.default
    
    func writeData(_ data: Data, to filePath: String) async throws {
        do {
            try data.write(to: URL(fileURLWithPath: filePath), options: .atomic)
        } catch {
            throw SimutransError.fileAccessError("Failed to write to file: \(error.localizedDescription)")
        }
    }
    
    func readData(from filePath: String, timeout: TimeInterval) async throws -> Data {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            do {
                // Check if file exists
                guard fileManager.fileExists(atPath: filePath) else {
                    // Wait a bit before checking again
                    try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                    continue
                }
                
                // Read file content
                guard let data = fileManager.contents(atPath: filePath) else {
                    // File exists but couldn't read content, wait and retry
                    try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                    continue
                }
                
                // If file is empty, wait and retry
                if data.isEmpty {
                    try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                    continue
                }
                
                return data
            } catch {
                // Handle any errors during sleep
                continue
            }
        }
        
        throw SimutransError.commandTimeout
    }
    
    func isFileEmpty(_ filePath: String) async throws -> Bool {
        guard fileManager.fileExists(atPath: filePath) else {
            // If file doesn't exist, consider it empty
            return true
        }
        
        guard let data = fileManager.contents(atPath: filePath) else {
            throw SimutransError.fileAccessError("Failed to read file")
        }
        
        return data.isEmpty
    }
}

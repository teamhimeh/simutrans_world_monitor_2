import Foundation

/// Configuration for the Simutrans World Monitor Server
struct Configuration: Codable {
    /// Path to the input file where commands are written for Simutrans to read
    let inputFilePath: String
    
    /// Path to the output file where Simutrans writes the results
    let outputFilePath: String
    
    /// Timeout in seconds for waiting for a response from Simutrans
    let timeout: TimeInterval
    
    /// Discord bot token
    let discordToken: String
    
    /// Default language for Discord messages
    let defaultLanguage: String
    
    /// Supported languages
    let supportedLanguages: [String]
    
    /// Custom error messages
    struct ErrorMessages: Codable {
        let commandTimeout: String
        let fileAccessError: String
        let jsonParsingError: String
        let simulationError: String
        let unknownError: String
    }
    
    /// Error messages for different languages
    let errorMessages: [String: ErrorMessages]
    
    /// Loads configuration from a file
    /// - Parameter filePath: Path to the configuration file
    /// - Returns: The loaded configuration
    /// - Throws: Error if loading fails
    static func load(from filePath: String) throws -> Configuration {
        let url = URL(fileURLWithPath: filePath)
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(Configuration.self, from: data)
    }
}

/// Extension to provide default values for Configuration
extension Configuration {
    /// Creates a default configuration
    /// - Returns: A configuration with default values
    static func defaultConfiguration() -> Configuration {
        return Configuration(
            inputFilePath: "simutrans_input.json",
            outputFilePath: "simutrans_output.json",
            timeout: 15.0,
            discordToken: "YOUR_DISCORD_TOKEN",
            defaultLanguage: "en",
            supportedLanguages: ["en", "ja"],
            errorMessages: [
                "en": ErrorMessages(
                    commandTimeout: "Command timed out",
                    fileAccessError: "Failed to access file",
                    jsonParsingError: "Failed to parse JSON",
                    simulationError: "Simulation error",
                    unknownError: "Unknown error"
                ),
                "ja": ErrorMessages(
                    commandTimeout: "コマンドがタイムアウトしました",
                    fileAccessError: "ファイルへのアクセスに失敗しました",
                    jsonParsingError: "JSONの解析に失敗しました",
                    simulationError: "シミュレーションエラー",
                    unknownError: "不明なエラー"
                )
            ]
        )
    }
}

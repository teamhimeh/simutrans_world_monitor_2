import Foundation

/// Localization manager for multi-language support
struct Localization {
    /// Dictionary of localized strings for each language
    private let localizedStrings: [String: [String: String]]
    
    /// Default language to use when a requested language is not available
    private let defaultLanguage: String
    
    /// Initializes a new localization manager
    /// - Parameters:
    ///   - localizedStrings: Dictionary of localized strings for each language
    ///   - defaultLanguage: Default language to use when a requested language is not available
    init(localizedStrings: [String: [String: String]], defaultLanguage: String) {
        self.localizedStrings = localizedStrings
        self.defaultLanguage = defaultLanguage
    }
    
    /// Gets a localized string for a given key and language
    /// - Parameters:
    ///   - key: The key for the localized string
    ///   - language: The language to use
    ///   - args: Optional arguments to format into the string
    /// - Returns: The localized string, or the key itself if not found
    func localized(_ key: String, language: String, _ args: String...) -> String {
        // Get the strings for the requested language, or fall back to the default language
        let strings = localizedStrings[language] ?? localizedStrings[defaultLanguage] ?? [:]
        
        // Get the localized string for the key, or fall back to the key itself
        var localizedString = strings[key] ?? key
        
        // Replace placeholders with arguments
        for (index, arg) in args.enumerated() {
            localizedString = localizedString.replacingOccurrences(of: "{\(index)}", with: arg)
        }
        
        return localizedString
    }
    
    /// Creates a localization manager from a configuration
    /// - Parameter config: The configuration to use
    /// - Returns: A new localization manager
    static func fromConfiguration(_ config: Configuration) -> Localization {
        // Create a dictionary of localized strings for each language
        var localizedStrings: [String: [String: String]] = [:]
        
        // Add error messages for each language
        for (language, errorMessages) in config.errorMessages {
            localizedStrings[language] = [
                "error.commandTimeout": errorMessages.commandTimeout,
                "error.fileAccessError": errorMessages.fileAccessError,
                "error.jsonParsingError": errorMessages.jsonParsingError,
                "error.simulationError": errorMessages.simulationError,
                "error.unknownError": errorMessages.unknownError,
                
                // Command responses
                "command.getPlayerList.success": "Player list retrieved successfully:",
                "command.getPlayerList.empty": "No players found.",
                "command.getLines.success": "Lines for player {0} retrieved successfully:",
                "command.getLines.empty": "No lines found for player {0}.",
                
                // Help messages
                "help.title": "Simutrans World Monitor - Help",
                "help.description": "This bot allows you to monitor your Simutrans world via Discord.",
                "help.commands": "Available commands:",
                "help.command.players": "!players - Get the list of players in the game",
                "help.command.lines": "!lines <player_index> <way_type> - Get the list of lines for a player",
                "help.command.help": "!help - Show this help message",
                "help.command.language": "!language <language> - Set your preferred language",
                
                // General messages
                "general.languageChanged": "Language changed to {0}.",
                "general.languageNotSupported": "Language {0} is not supported. Available languages: {1}",
                "general.unknownCommand": "Unknown command. Type !help for a list of available commands."
            ]
        }
        
        return Localization(localizedStrings: localizedStrings, defaultLanguage: config.defaultLanguage)
    }
}

/// Extension to add Japanese localized strings
extension Localization {
    /// Adds Japanese localized strings to the localization manager
    /// - Returns: A new localization manager with Japanese strings added
    static func withJapaneseStrings(_ localization: Localization) -> Localization {
        var localizedStrings = localization.localizedStrings
        
        // Add Japanese strings
        localizedStrings["ja"] = [
            // Command responses
            "command.getPlayerList.success": "プレイヤーリストの取得に成功しました：",
            "command.getPlayerList.empty": "プレイヤーが見つかりませんでした。",
            "command.getLines.success": "プレイヤー {0} の路線の取得に成功しました：",
            "command.getLines.empty": "プレイヤー {0} の路線が見つかりませんでした。",
            
            // Help messages
            "help.title": "Simutrans World Monitor - ヘルプ",
            "help.description": "このボットはDiscordを通じてSimutransの世界を監視することができます。",
            "help.commands": "利用可能なコマンド：",
            "help.command.players": "!players - ゲーム内のプレイヤーリストを取得",
            "help.command.lines": "!lines <player_index> <way_type> - プレイヤーの路線リストを取得",
            "help.command.help": "!help - このヘルプメッセージを表示",
            "help.command.language": "!language <language> - 優先言語を設定",
            
            // General messages
            "general.languageChanged": "言語が {0} に変更されました。",
            "general.languageNotSupported": "言語 {0} はサポートされていません。利用可能な言語：{1}",
            "general.unknownCommand": "不明なコマンドです。利用可能なコマンドのリストを表示するには !help と入力してください。"
        ]
        
        return Localization(
            localizedStrings: localizedStrings,
            defaultLanguage: localization.defaultLanguage
        )
    }
}

import Foundation
import DiscordBM

/// Discord bot for interacting with Simutrans
@MainActor class DiscordBot {
    /// The Discord client
    private let client: any DiscordClient
    
    /// The gateway manager
    private let gateway: any GatewayManager
    
    /// The Simutrans interface
    private let simutransInterface: SimutransInterface
    
    /// The localization manager
    private let localization: Localization
    
    /// User language preferences
    private var userLanguagePreferences: [String: String] = [:]
    
    /// Default language
    private let defaultLanguage: String
    
    /// Supported languages
    private let supportedLanguages: [String]
    
    /// JSON encoder for encoding commands
    private let encoder = JSONEncoder()
    
    /// JSON decoder for decoding responses
    private let decoder = JSONDecoder()
    
    /// Initializes a new Discord bot
    /// - Parameters:
    ///   - client: The Discord client
    ///   - gateway: The gateway manager
    ///   - simutransInterface: The Simutrans interface
    ///   - localization: The localization manager
    ///   - defaultLanguage: The default language
    ///   - supportedLanguages: The supported languages
    init(
        client: any DiscordClient,
        gateway: any GatewayManager,
        simutransInterface: SimutransInterface,
        localization: Localization,
        defaultLanguage: String,
        supportedLanguages: [String]
    ) {
        self.client = client
        self.gateway = gateway
        self.simutransInterface = simutransInterface
        self.localization = localization
        self.defaultLanguage = defaultLanguage
        self.supportedLanguages = supportedLanguages
    }
    
    /// Starts the Discord bot
    /// - Throws: Error if starting fails
    func start() async throws {
        // Register slash commands
        try await registerCommands()
        
        // Set up interaction handler for slash commands
        Task {
            for await event in await gateway.events {
                switch event.data {
                case .interactionCreate(let interaction):
                    await handleInteraction(interaction)
                default:
                    break
                }
            }
        }
        
        // Connect to Discord
        await gateway.connect()
    }
    
    /// Stops the Discord bot
    func stop() async {
        await gateway.disconnect()
    }
    
    /// Registers slash commands with Discord
    /// - Throws: Error if registration fails
    private func registerCommands() async throws {
        // Define the commands
        let commands: [Payloads.ApplicationCommandCreate] = [
            // Help command
            .init(
                name: "help",
                description: "Show help information",
                options: []
            ),
            
            // Language command
            .init(
                name: "language",
                description: "Set your preferred language",
                options: [
                    .init(
                        type: .string,
                        name: "language",
                        description: "The language code (e.g., en, ja)",
                        required: true,
                        choices: supportedLanguages.map { lang in
                            .init(name: lang, value: .string(lang))
                        }
                    )
                ]
            ),
            
            // Players command
            .init(
                name: "players",
                description: "Get the list of players in the game",
                options: []
            ),
            
            // Lines command
            .init(
                name: "lines",
                description: "Get the list of lines for a player",
                options: [
                    .init(
                        type: .integer,
                        name: "player_index",
                        description: "The index of the player",
                        required: true
                    ),
                    .init(
                        type: .string,
                        name: "way_type",
                        description: "The type of transportation way",
                        required: true,
                        choices: [
                            .init(name: "Road", value: .string("road")),
                            .init(name: "Rail", value: .string("rail")),
                            .init(name: "Water", value: .string("water")),
                            .init(name: "Monorail", value: .string("monorail")),
                            .init(name: "Maglev", value: .string("maglev")),
                            .init(name: "Tram", value: .string("tram")),
                            .init(name: "Narrow Gauge", value: .string("narrow")),
                            .init(name: "Air", value: .string("air"))
                        ]
                    )
                ]
            )
        ]
        
        // Register the commands globally
        try await client.bulkSetApplicationCommands(payload: commands).guardSuccess()
    }
    
    /// Handles an interaction from Discord
    /// - Parameter interaction: The interaction to handle
    private func handleInteraction(_ interaction: Interaction) async {
        // Only handle application command interactions
        guard case let .applicationCommand(data) = interaction.data else { return }
        
        // Get the user's preferred language
        let userId = interaction.user?.id.rawValue ?? interaction.member?.user?.id.rawValue ?? ""
        let language = userLanguagePreferences[userId] ?? defaultLanguage
        
        // Handle the command
        switch data.name {
        case "help":
            await handleHelpCommand(interaction: interaction, language: language)
        case "language":
            await handleLanguageCommand(interaction: interaction, language: language)
        case "players":
            await handlePlayersCommand(interaction: interaction, language: language)
        case "lines":
            await handleLinesCommand(interaction: interaction, language: language)
        default:
            // This shouldn't happen since we only register specific commands
            await respondToInteraction(interaction: interaction, content: "Unknown command", ephemeral: true)
        }
    }
    
    /// Responds to an interaction with an initial waiting message
    /// - Parameters:
    ///   - interaction: The interaction to respond to
    ///   - content: The content of the response
    ///   - ephemeral: Whether the response should be ephemeral (only visible to the user)
    private func respondToInteraction(interaction: Interaction, content: String, ephemeral: Bool = false) async {
        do {
            _ = try await client.createInteractionResponse(
                id: interaction.id,
                token: interaction.token,
                payload: .channelMessageWithSource(.init(
                    content: content,
                    flags: ephemeral ? [.ephemeral] : []
                ))
            )
        } catch {
            print("Error responding to interaction: \(error)")
        }
    }
    
    /// Updates an interaction response with new content
    /// - Parameters:
    ///   - interaction: The original interaction
    ///   - content: The new content for the response
    private func updateInteractionResponse(interaction: Interaction, content: String) async {
        do {
            _ = try await client.updateOriginalInteractionResponse(
                token: interaction.token,
                payload: .init(content: content)
            )
        } catch {
            print("Error updating interaction response: \(error)")
        }
    }
    
    /// Handles the help command
    /// - Parameters:
    ///   - interaction: The interaction to respond to
    ///   - language: The language to use
    private func handleHelpCommand(interaction: Interaction, language: String) async {
        let title = localization.localized("help.title", language: language)
        let description = localization.localized("help.description", language: language)
        let commands = localization.localized("help.commands", language: language)
        let playersCommand = localization.localized("help.command.players", language: language)
        let linesCommand = localization.localized("help.command.lines", language: language)
        let helpCommand = localization.localized("help.command.help", language: language)
        let languageCommand = localization.localized("help.command.language", language: language)
        
        let message = """
        **\(title)**
        \(description)
        
        **\(commands)**
        /\(helpCommand)
        /\(playersCommand)
        /\(linesCommand)
        /\(languageCommand)
        """
        
        await respondToInteraction(interaction: interaction, content: message)
    }
    
    /// Handles the language command
    /// - Parameters:
    ///   - interaction: The interaction to respond to
    ///   - language: The language to use
    private func handleLanguageCommand(interaction: Interaction, language: String) async {
        // Get the new language from the options
        guard case let .applicationCommand(data) = interaction.data,
              let options = data.options,
              let languageOption = options.first(where: { $0.name == "language" }),
              case let .string(newLanguage) = languageOption.value else {
            await respondToInteraction(
                interaction: interaction,
                content: localization.localized("general.languageChanged", language: language, language),
                ephemeral: true
            )
            return
        }
        
        // Check if the language is supported
        if supportedLanguages.contains(newLanguage) {
            // Update the user's language preference
            if let userId = interaction.user?.id.rawValue ?? interaction.member?.user?.id.rawValue {
                userLanguagePreferences[userId] = newLanguage
            }
            
            // Send a confirmation message
            let message = localization.localized("general.languageChanged", language: newLanguage, newLanguage)
            await respondToInteraction(interaction: interaction, content: message, ephemeral: true)
        } else {
            // Send an error message
            let supportedLanguagesString = supportedLanguages.joined(separator: ", ")
            let message = localization.localized("general.languageNotSupported", language: language, newLanguage, supportedLanguagesString)
            await respondToInteraction(interaction: interaction, content: message, ephemeral: true)
        }
    }
    
    /// Handles the players command
    /// - Parameters:
    ///   - interaction: The interaction to respond to
    ///   - language: The language to use
    private func handlePlayersCommand(interaction: Interaction, language: String) async {
        // Send initial waiting message
        let waitingMessage = localization.localized("command.waiting", language: language)
        await respondToInteraction(interaction: interaction, content: waitingMessage)
        
        do {
            // Create the command
            let command = GetPlayerListCommand()
            let commandData = try encoder.encode(command)
            
            // Send the command to Simutrans
            let responseData = try await simutransInterface.sendData(commandData)
            
            // Decode the response
            let response = try decoder.decode(PlayerListResponse.self, from: responseData)
            
            // Check if there are any players
            if response.result.isEmpty {
                let message = localization.localized("command.getPlayerList.empty", language: language)
                await updateInteractionResponse(interaction: interaction, content: message)
                return
            }
            
            // Format the player list
            let successMessage = localization.localized("command.getPlayerList.success", language: language)
            var message = successMessage + "\n"
            
            for player in response.result {
                message += "- \(player.name) (Index: \(player.index))\n"
            }
            
            // Update the message with the results
            await updateInteractionResponse(interaction: interaction, content: message)
        } catch {
            // Handle errors
            await sendErrorMessage(error: error, interaction: interaction, language: language)
        }
    }
    
    /// Handles the lines command
    /// - Parameters:
    ///   - interaction: The interaction to respond to
    ///   - language: The language to use
    private func handleLinesCommand(interaction: Interaction, language: String) async {
        // Get the player index and way type from the options
        guard case let .applicationCommand(data) = interaction.data,
              let options = data.options,
              let playerIndexOption = options.first(where: { $0.name == "player_index" }),
              let wayTypeOption = options.first(where: { $0.name == "way_type" }),
              case let .int(playerIndex) = playerIndexOption.value,
              case let .string(wayTypeString) = wayTypeOption.value,
              let wayType = WayType(rawValue: wayTypeString) else {
            let message = localization.localized("help.command.lines", language: language)
            await respondToInteraction(interaction: interaction, content: message, ephemeral: true)
            return
        }
        
        // Send initial waiting message
        let waitingMessage = localization.localized("command.waiting", language: language)
        await respondToInteraction(interaction: interaction, content: waitingMessage)
        
        do {
            // Create the command
            let command = GetLinesCommand(playerIndex: Int(playerIndex), wayType: wayType)
            let commandData = try encoder.encode(command)
            
            // Send the command to Simutrans
            let responseData = try await simutransInterface.sendData(commandData)
            
            // Decode the response
            let response = try decoder.decode(LinesResponse.self, from: responseData)
            
            // Check if there are any lines
            if response.result.isEmpty {
                let message = localization.localized("command.getLines.empty", language: language, String(playerIndex))
                await updateInteractionResponse(interaction: interaction, content: message)
                return
            }
            
            // Format the line list
            let successMessage = localization.localized("command.getLines.success", language: language, String(playerIndex))
            var message = successMessage + "\n"
            
            for line in response.result {
                message += "- \(line.name) (ID: \(line.id))\n"
            }
            
            // Update the message with the results
            await updateInteractionResponse(interaction: interaction, content: message)
        } catch {
            // Handle errors
            await sendErrorMessage(error: error, interaction: interaction, language: language)
        }
    }
    
    /// Sends an error message in response to an interaction
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - interaction: The interaction to respond to
    ///   - language: The language to use
    private func sendErrorMessage(error: Error, interaction: Interaction, language: String) async {
        let message: String
        
        if let simutransError = error as? SimutransError {
            switch simutransError {
            case .commandTimeout:
                message = localization.localized("error.commandTimeout", language: language)
            case .fileAccessError(let description):
                message = localization.localized("error.fileAccessError", language: language, description)
            case .jsonParsingError(let description):
                message = localization.localized("error.jsonParsingError", language: language, description)
            case .simulationError(let description):
                message = localization.localized("error.simulationError", language: language, description)
            case .unknownError(let description):
                message = localization.localized("error.unknownError", language: language, description)
            }
        } else {
            message = localization.localized("error.unknownError", language: language, error.localizedDescription)
        }
        
        // Check if we've already sent an initial response
        if interaction.token.isEmpty {
            // If not, send a new response
            await respondToInteraction(interaction: interaction, content: message, ephemeral: true)
        } else {
            // If we have, update the existing response
            await updateInteractionResponse(interaction: interaction, content: message)
        }
    }
}

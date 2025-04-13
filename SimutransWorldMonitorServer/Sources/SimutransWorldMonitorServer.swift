import Foundation
import DiscordBM
import NIO
import Dispatch

/// Main entry point for the application
@main @MainActor
struct SimutransWorldMonitorServer {
    /// Shared instance of the Discord bot for signal handling
    static var sharedDiscordBot: DiscordBot?
    
    /// Runs the application
    static func main() async throws {
        print("Starting Simutrans World Monitor Server...")
        
        // Load configuration
        let config: Configuration
        do {
            config = try Configuration.load(from: "config.json")
            print("Configuration loaded successfully")
        } catch {
            print("Error loading configuration: \(error)")
            print("Using default configuration")
            config = Configuration.defaultConfiguration()
        }
        
        // Create localization
        let baseLocalization = Localization.fromConfiguration(config)
        let localization = Localization.withJapaneseStrings(baseLocalization)
        
        // Create file I/O
        let fileIO = SimutransFileIO()
        
        // Create Simutrans interface
        let simutransInterface = SimutransInterface(
            fileIO: fileIO,
            inputFilePath: config.inputFilePath,
            outputFilePath: config.outputFilePath,
            timeout: config.timeout
        )
        
        // Create Discord client and gateway
        let gateway = await ShardingGatewayManager(
            token: config.discordToken, 
            intents: Gateway.Intent.unprivileged
        )
        let client = gateway.client
        
        // Create Discord bot
        let discordBot = DiscordBot(
            client: client,
            gateway: gateway,
            simutransInterface: simutransInterface,
            localization: localization,
            defaultLanguage: config.defaultLanguage,
            supportedLanguages: config.supportedLanguages
        )
        
        // Store the Discord bot for signal handling
        sharedDiscordBot = discordBot
        
        // Set up signal handling for graceful shutdown
        setupSignalHandling()
        
        // Start the Discord bot
        do {
            print("Starting Discord bot...")
            try await discordBot.start()
            print("Discord bot started successfully")
        } catch {
            print("Error starting Discord bot: \(error)")
            exit(1)
        }
        
        // Keep the application running
        while true {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
    }
    
    /// Sets up signal handling for graceful shutdown
    static func setupSignalHandling() {
        // Set up signal handling for SIGINT (Ctrl+C)
        let sigintSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        sigintSource.setEventHandler {
            print("\nReceived SIGINT, shutting down...")
            Task {
                await sharedDiscordBot?.stop()
                print("Discord bot stopped")
                exit(0)
            }
        }
        sigintSource.resume()
        
        // Set up signal handling for SIGTERM
        let sigtermSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        sigtermSource.setEventHandler {
            print("Received SIGTERM, shutting down...")
            Task {
                await sharedDiscordBot?.stop()
                print("Discord bot stopped")
                exit(0)
            }
        }
        sigtermSource.resume()
        
        // Ignore the signals at the process level
        signal(SIGINT, SIG_IGN)
        signal(SIGTERM, SIG_IGN)
    }
}

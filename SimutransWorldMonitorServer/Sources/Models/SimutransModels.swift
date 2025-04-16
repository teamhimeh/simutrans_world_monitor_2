import Foundation

// MARK: - Command Models

/// Base protocol for all Simutrans commands
protocol SimutransCommand: Codable {
    var command: String { get }
    var id: String { get }
}

/// Command to get the list of players in the game
struct GetPlayerListCommand: SimutransCommand {
    let command = "get_player_list"
    let id: String
    
    init(id: String = UUID().uuidString) {
        self.id = id
    }
    
    enum CodingKeys: String, CodingKey {
        case command
        case id
    }
}

/// Command to get the list of lines owned by a player
struct GetLinesCommand: SimutransCommand {
    let command = "get_lines"
    let id: String
    let player_index: Int
    let way_type: WayType
    
    init(id: String = UUID().uuidString, playerIndex: Int, wayType: WayType) {
        self.id = id
        self.player_index = playerIndex
        self.way_type = wayType
    }
    
    enum CodingKeys: String, CodingKey {
        case command
        case id
        case player_index
        case way_type
    }
}

// MARK: - Response Models

/// Base protocol for all Simutrans responses
protocol SimutransResponse: Codable {
    var command: String { get }
    var id: String { get }
}

/// Response for the get_player_list command
struct PlayerListResponse: SimutransResponse {
    let command: String
    let id: String
    let result: [Player]
    
    struct Player: Codable {
        let index: Int
        let name: String
    }
}

/// Response for the get_lines command
struct LinesResponse: SimutransResponse {
    let command: String
    let id: String
    let result: [Line]
    
    struct Line: Codable {
        let id: Int
        let name: String
    }
}

/// Error response from Simutrans
struct ErrorResponse: SimutransResponse {
    let command = "error"
    let id: String
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case command
        case id
        case description
    }
}

// MARK: - Enums

/// Enum representing the different types of transportation ways in Simutrans
enum WayType: String, Codable {
    case road = "road"
    case rail = "rail"
    case water = "water"
    case monorail = "monorail"
    case maglev = "maglev"
    case tram = "tram"
    case narrow = "narrow"
    case air = "air"
}

// MARK: - Errors

/// Errors that can occur when interacting with Simutrans
enum SimutransError: Error {
    case commandTimeout
    case fileAccessError(String)
    case jsonParsingError(String)
    case simulationError(String)
    case unknownError(String)
}

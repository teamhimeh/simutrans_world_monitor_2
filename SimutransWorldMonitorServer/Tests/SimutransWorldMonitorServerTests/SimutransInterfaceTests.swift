import Foundation
import Testing
@testable import SimutransWorldMonitorServer

/// Tests for SimutransInterface
struct SimutransInterfaceTests {
    /// Tests sending data to Simutrans
    @Test func testSendData() async throws {
        // Create a mock file I/O
        let mockFileIO = MockSimutransFileIO()
        
        // Create a Simutrans interface with the mock file I/O
        let interface = SimutransInterface(
            fileIO: mockFileIO,
            inputFilePath: "input.json",
            outputFilePath: "output.json",
            timeout: 1.0
        )
        
        // Set up the mock to return a specific response
        await mockFileIO.setOutputFileData("Test response".data(using: .utf8)!)
        
        // Send some data
        let inputData = "Test command".data(using: .utf8)!
        let outputData = try await interface.sendData(inputData)
        
        // Verify the output
        let outputString = String(data: outputData, encoding: .utf8)
        #expect(outputString == "Test response")
        
        // Verify the input was written to the correct file
        let inputFileData = await mockFileIO.getInputFileData()
        let inputString = String(data: inputFileData, encoding: .utf8)
        #expect(inputString == "Test command")
    }
    
    /// Tests sending a player list command
    @Test func testSendPlayerListCommand() async throws {
        // Create a mock file I/O
        let mockFileIO = MockSimutransFileIO()
        
        // Create a Simutrans interface with the mock file I/O
        let interface = SimutransInterface(
            fileIO: mockFileIO,
            inputFilePath: "input.json",
            outputFilePath: "output.json",
            timeout: 1.0
        )
        
        // Create the command
        let command = GetPlayerListCommand()
        let encoder = JSONEncoder()
        let commandData = try encoder.encode(command)
        
        // Set up the mock to return a specific response
        let response = PlayerListResponse(
            command: "get_player_list",
            id: command.id,
            result: [
                .init(index: "0", name: "Player 1"),
                .init(index: "1", name: "Player 2")
            ]
        )
        let responseData = try encoder.encode(response)
        await mockFileIO.setOutputFileData(responseData)
        
        // Send the command
        let receivedData = try await interface.sendData(commandData)
        
        // Decode the response
        let decoder = JSONDecoder()
        let receivedResponse = try decoder.decode(PlayerListResponse.self, from: receivedData)
        
        // Verify the response
        #expect(receivedResponse.command == "get_player_list")
        #expect(receivedResponse.result.count == 2)
        #expect(receivedResponse.result[0].index == "0")
        #expect(receivedResponse.result[0].name == "Player 1")
        #expect(receivedResponse.result[1].index == "1")
        #expect(receivedResponse.result[1].name == "Player 2")
    }
    
    /// Tests sending a lines command
    @Test func testSendLinesCommand() async throws {
        // Create a mock file I/O
        let mockFileIO = MockSimutransFileIO()
        
        // Create a Simutrans interface with the mock file I/O
        let interface = SimutransInterface(
            fileIO: mockFileIO,
            inputFilePath: "input.json",
            outputFilePath: "output.json",
            timeout: 1.0
        )
        
        // Create the command
        let command = GetLinesCommand(playerIndex: 0, wayType: .road)
        let encoder = JSONEncoder()
        let commandData = try encoder.encode(command)
        
        // Set up the mock to return a specific response
        let response = LinesResponse(
            command: "get_lines",
            id: command.id,
            result: [
                .init(id: 1, name: "Line 1"),
                .init(id: 2, name: "Line 2")
            ]
        )
        let responseData = try encoder.encode(response)
        await mockFileIO.setOutputFileData(responseData)
        
        // Send the command
        let receivedData = try await interface.sendData(commandData)
        
        // Decode the response
        let decoder = JSONDecoder()
        let receivedResponse = try decoder.decode(LinesResponse.self, from: receivedData)
        
        // Verify the response
        #expect(receivedResponse.command == "get_lines")
        #expect(receivedResponse.result.count == 2)
        #expect(receivedResponse.result[0].id == 1)
        #expect(receivedResponse.result[0].name == "Line 1")
        #expect(receivedResponse.result[1].id == 2)
        #expect(receivedResponse.result[1].name == "Line 2")
    }
    
    /// Tests handling an error response
    @Test func testErrorResponse() async throws {
        // Create a mock file I/O
        let mockFileIO = MockSimutransFileIO()
        
        // Create a Simutrans interface with the mock file I/O
        let interface = SimutransInterface(
            fileIO: mockFileIO,
            inputFilePath: "input.json",
            outputFilePath: "output.json",
            timeout: 1.0
        )
        
        // Create the command
        let command = GetPlayerListCommand()
        let encoder = JSONEncoder()
        let commandData = try encoder.encode(command)
        
        // Set up the mock to return an error response
        let errorResponse = ErrorResponse(
            id: command.id,
            description: "Test error"
        )
        let responseData = try encoder.encode(errorResponse)
        await mockFileIO.setOutputFileData(responseData)
        
        // Send the command
        let receivedData = try await interface.sendData(commandData)
        
        // Decode the response
        let decoder = JSONDecoder()
        let receivedResponse = try decoder.decode(ErrorResponse.self, from: receivedData)
        
        // Verify the response
        #expect(receivedResponse.command == "error")
        #expect(receivedResponse.description == "Test error")
    }
}

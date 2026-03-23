@testable import TazendorAnthropic
import Foundation
import TazendorAI
import Testing

/// Tests for tool definition encoding and tool use round-trips.
struct ToolDefinitionTests {
    @Test("ToolDefinition encodes to correct JSON structure")
    func toolDefinition_encodesCorrectly() throws {
        let tool = ToolDefinition(
            name: "get_weather",
            description: "Get the current weather",
            inputSchema: ToolInputSchema(
                type: "object",
                properties: [
                    "location": .object([
                        "type": .string("string"),
                        "description": .string("City and state"),
                    ]),
                    "unit": .object([
                        "type": .string("string"),
                        "enum": .array([.string("celsius"), .string("fahrenheit")]),
                    ]),
                ],
                required: ["location"],
            ),
        )

        let data = try JSONCoders.encoder.encode(tool)
        let decoded = try JSONCoders.decoder.decode(
            ToolDefinition.self,
            from: data,
        )

        #expect(decoded.name == "get_weather")
        #expect(decoded.description == "Get the current weather")
        #expect(decoded.inputSchema.type == "object")
        #expect(decoded.inputSchema.required == ["location"])
    }

    @Test("MessageRequest with tools encodes correctly")
    func messageRequest_withTools_encodesCorrectly() throws {
        let tool = ToolDefinition(
            name: "calculate",
            description: "Perform a calculation",
            inputSchema: ToolInputSchema(
                properties: [
                    "expression": .object([
                        "type": .string("string"),
                    ]),
                ],
                required: ["expression"],
            ),
        )

        let request = MessageRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [InputMessage(role: .user, text: "What is 2+2?")],
            tools: [tool],
            toolChoice: .auto,
        )

        let data = try JSONCoders.encoder.encode(request)
        let decoded = try JSONCoders.decoder.decode(
            MessageRequest.self,
            from: data,
        )

        #expect(decoded.tools?.count == 1)
        #expect(decoded.tools?.first?.name == "calculate")
        #expect(decoded.toolChoice == .auto)
    }

    @Test("Tool result input message round-trips correctly")
    func toolResult_roundTrip() throws {
        let message = InputMessage(
            role: .user,
            content: [
                .toolResult(
                    toolUseId: "toolu_01A09q90qw90lq917835lq9",
                    content: "{\"temperature\": 72, \"unit\": \"fahrenheit\"}",
                    isError: false,
                ),
            ],
        )

        let data = try JSONCoders.encoder.encode(message)
        let decoded = try JSONCoders.decoder.decode(
            InputMessage.self,
            from: data,
        )

        guard case let .toolResult(id, content, isError)
            = decoded.content.first
        else {
            Issue.record("Expected toolResult")
            return
        }
        #expect(id == "toolu_01A09q90qw90lq917835lq9")
        #expect(content.contains("temperature"))
        #expect(isError == false)
    }

    @Test("Full tool use conversation cycle encodes/decodes")
    func fullToolUseCycle_roundTrips() throws {
        // 1. User asks a question
        let userMessage = InputMessage(role: .user, text: "What's the weather in NYC?")

        // 2. Assistant responds with tool use (simulated response)
        let toolUseResponse = MessageResponse(
            id: "msg_01",
            content: [
                .text(TextBlock(text: "I'll check the weather.")),
                .toolUse(ToolUseBlock(
                    id: "toolu_01",
                    name: "get_weather",
                    input: .object(["location": .string("NYC")]),
                )),
            ],
            model: "claude-sonnet-4-6",
            stopReason: .toolUse,
        )

        // Verify the response decodes correctly
        let responseData = try JSONCoders.encoder.encode(toolUseResponse)
        let decodedResponse = try JSONCoders.decoder.decode(
            MessageResponse.self,
            from: responseData,
        )
        #expect(decodedResponse.stopReason == .toolUse)
        #expect(decodedResponse.content.count == 2)

        // 3. User sends tool result back
        let toolResultMessage = InputMessage(
            role: .user,
            content: [
                .toolResult(
                    toolUseId: "toolu_01",
                    content: "72°F, sunny",
                    isError: false,
                ),
            ],
        )

        // 4. Verify the follow-up request encodes correctly
        let followUp = MessageRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [userMessage, toolResultMessage],
        )

        let followUpData = try JSONCoders.encoder.encode(followUp)
        let decodedFollowUp = try JSONCoders.decoder.decode(
            MessageRequest.self,
            from: followUpData,
        )
        #expect(decodedFollowUp.messages.count == 2)
    }

    @Test("JSONValue handles nested tool input structures")
    func jsonValue_nestedStructures() throws {
        let input: JSONValue = .object([
            "query": .string("SELECT * FROM users"),
            "params": .array([.string("active"), .number(42)]),
            "options": .object([
                "limit": .number(10),
                "offset": .number(0),
                "verbose": .bool(true),
            ]),
            "filter": .null,
        ])

        let data = try JSONCoders.encoder.encode(input)
        let decoded = try JSONCoders.decoder.decode(
            JSONValue.self,
            from: data,
        )
        #expect(decoded == input)
    }

    @Test("All ToolChoice variants encode with correct type field")
    func toolChoice_allVariants_encodeCorrectType() throws {
        let cases: [(ToolChoice, String)] = [
            (.auto, "auto"),
            (.any, "any"),
            (.tool(name: "calc"), "tool"),
            (.none, "none"),
        ]

        for (choice, expectedType) in cases {
            let data = try JSONCoders.encoder.encode(choice)
            let json = try JSONCoders.decoder.decode(
                [String: JSONValue].self,
                from: data,
            )
            guard case let .string(type) = json["type"] else {
                Issue.record("Expected type field for \(choice)")
                return
            }
            #expect(type == expectedType)
        }
    }
}

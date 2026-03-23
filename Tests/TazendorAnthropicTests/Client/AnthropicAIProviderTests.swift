import Foundation
import TazendorAI
@testable import TazendorAnthropic
import Testing

struct AnthropicAIProviderTests {
    private let mockClient = MockAnthropicClient()

    private var provider: AnthropicAIProvider {
        AnthropicAIProvider(client: mockClient)
    }

    // MARK: - Provider Identity

    @Test
    func providerID_returnsAnthropic() {
        #expect(provider.providerID == "anthropic")
    }

    @Test
    func capabilities_includesExpectedSet() {
        let caps = provider.capabilities
        #expect(caps.contains(.textGeneration))
        #expect(caps.contains(.streaming))
        #expect(caps.contains(.toolUse))
        #expect(caps.contains(.vision))
        #expect(caps.contains(.thinking))
    }

    // MARK: - sendMessage Request Mapping

    @Test
    func sendMessage_simpleText_mapsRequestCorrectly() async throws {
        mockClient.sendResult = .success(makeTextResponse())

        let request = AIRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [AIMessage(role: .user, text: "Hello")],
        )

        _ = try await provider.sendMessage(request)

        let mapped = try #require(mockClient.lastSendRequest)
        #expect(mapped.model == "claude-sonnet-4-6")
        #expect(mapped.maxTokens == 1024)
        #expect(mapped.messages.count == 1)
        #expect(mapped.messages[0].role == .user)
    }

    @Test
    func sendMessage_withSystemPrompt_mapsToSystem() async throws {
        mockClient.sendResult = .success(makeTextResponse())

        let request = AIRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [AIMessage(role: .user, text: "Hi")],
            systemPrompt: "You are helpful.",
        )

        _ = try await provider.sendMessage(request)

        let mapped = try #require(mockClient.lastSendRequest)
        #expect(mapped.system == .text("You are helpful."))
    }

    @Test
    func sendMessage_withTools_passesToolDefinitions() async throws {
        mockClient.sendResult = .success(makeTextResponse())

        let tool = ToolDefinition(
            name: "get_weather",
            description: "Get weather",
            inputSchema: ToolInputSchema(
                properties: ["city": .object(["type": "string"])],
                required: ["city"],
            ),
        )

        let request = AIRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [AIMessage(role: .user, text: "Weather?")],
            tools: [tool],
        )

        _ = try await provider.sendMessage(request)

        let mapped = try #require(mockClient.lastSendRequest)
        #expect(mapped.tools?.count == 1)
        #expect(mapped.tools?[0].name == "get_weather")
    }

    @Test
    func sendMessage_withThinkingOption_mapsToThinkingConfig() async throws {
        mockClient.sendResult = .success(makeTextResponse())

        let request = AIRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 16384,
            messages: [AIMessage(role: .user, text: "Think")],
            options: [.anthropicThinkingBudget: .number(10000)],
        )

        _ = try await provider.sendMessage(request)

        let mapped = try #require(mockClient.lastSendRequest)
        #expect(mapped.thinking == .enabled(budgetTokens: 10000))
    }

    @Test
    func sendMessage_withProviderOptions_mapsCorrectly() async throws {
        mockClient.sendResult = .success(makeTextResponse())

        let request = AIRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [AIMessage(role: .user, text: "Hi")],
            temperature: 0.7,
            stopSequences: ["END"],
            options: [
                .anthropicTopP: .number(0.9),
                .anthropicTopK: .number(40),
                .anthropicUserId: .string("user-123"),
            ],
        )

        _ = try await provider.sendMessage(request)

        let mapped = try #require(mockClient.lastSendRequest)
        #expect(mapped.temperature == 0.7)
        #expect(mapped.topP == 0.9)
        #expect(mapped.topK == 40)
        #expect(mapped.stopSequences == ["END"])
        #expect(mapped.metadata?.userId == "user-123")
    }

    // MARK: - sendMessage Response Mapping

    @Test
    func sendMessage_textResponse_mapsToAIResponse() async throws {
        mockClient.sendResult = .success(makeTextResponse())

        let request = AIRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [AIMessage(role: .user, text: "Hi")],
        )

        let response = try await provider.sendMessage(request)

        #expect(response.id == "msg_123")
        #expect(response.model == "claude-sonnet-4-6")
        #expect(response.content.count == 1)
        if case let .text(text) = response.content[0] {
            #expect(text == "Hello there!")
        } else {
            Issue.record("Expected text content part")
        }
        #expect(response.stopReason == .endTurn)
        #expect(response.usage?.inputTokens == 10)
        #expect(response.usage?.outputTokens == 5)
    }

    @Test
    func sendMessage_toolUseResponse_mapsToToolCall() async throws {
        let toolUseResponse = MessageResponse(
            id: "msg_456",
            content: [
                .toolUse(
                    ToolUseBlock(
                        id: "tu_1",
                        name: "get_weather",
                        input: .object(["city": "Paris"]),
                    ),
                ),
            ],
            model: "claude-sonnet-4-6",
            stopReason: .toolUse,
            usage: Usage(inputTokens: 20, outputTokens: 15),
        )
        mockClient.sendResult = .success(toolUseResponse)

        let request = AIRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [AIMessage(role: .user, text: "Weather?")],
        )

        let response = try await provider.sendMessage(request)

        #expect(response.stopReason == .toolUse)
        #expect(response.content.count == 1)
        if case let .toolCall(call) = response.content[0] {
            #expect(call.id == "tu_1")
            #expect(call.name == "get_weather")
            #expect(call.arguments == .object(["city": "Paris"]))
        } else {
            Issue.record("Expected toolCall content part")
        }
    }

    @Test
    func sendMessage_allStopReasons_mapCorrectly() async throws {
        let cases: [(StopReason, AIStopReason)] = [
            (.endTurn, .endTurn),
            (.maxTokens, .maxTokens),
            (.toolUse, .toolUse),
            (.stopSequence, .stopSequence),
        ]

        for (anthropicReason, expectedReason) in cases {
            let response = MessageResponse(
                id: "msg_1",
                content: [.text(TextBlock(text: "ok"))],
                model: "claude-sonnet-4-6",
                stopReason: anthropicReason,
            )
            mockClient.sendResult = .success(response)

            let request = AIRequest(
                model: "claude-sonnet-4-6",
                maxTokens: 1024,
                messages: [AIMessage(role: .user, text: "Hi")],
            )

            let aiResponse = try await provider.sendMessage(request)
            #expect(aiResponse.stopReason == expectedReason)
        }
    }

    @Test
    func sendMessage_thinkingBlocks_areSkipped() async throws {
        let response = MessageResponse(
            id: "msg_1",
            content: [
                .thinking(ThinkingBlock(thinking: "hmm", signature: "sig")),
                .text(TextBlock(text: "answer")),
            ],
            model: "claude-sonnet-4-6",
            stopReason: .endTurn,
        )
        mockClient.sendResult = .success(response)

        let request = AIRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [AIMessage(role: .user, text: "Think")],
        )

        let aiResponse = try await provider.sendMessage(request)
        #expect(aiResponse.content.count == 1)
        if case let .text(text) = aiResponse.content[0] {
            #expect(text == "answer")
        } else {
            Issue.record("Expected text, not thinking")
        }
    }

    // MARK: - sendMessage Error Mapping

    @Test
    func sendMessage_apiError_mapsToAIError() async throws {
        let apiResponse = APIErrorResponse(
            type: "error",
            error: .init(type: "invalid_request_error", message: "bad model"),
        )
        mockClient.sendResult = .failure(
            .apiError(statusCode: 400, response: apiResponse),
        )

        let request = AIRequest(
            model: "bad-model",
            maxTokens: 1024,
            messages: [AIMessage(role: .user, text: "Hi")],
        )

        do {
            _ = try await provider.sendMessage(request)
            Issue.record("Expected error")
        } catch let error as AIError {
            if case let .apiError(statusCode, message) = error {
                #expect(statusCode == 400)
                #expect(message == "bad model")
            } else {
                Issue.record("Expected apiError, got \(error)")
            }
        }
    }

    // MARK: - Content Part Mapping

    @Test
    func sendMessage_toolResultMessage_mapsCorrectly() async throws {
        mockClient.sendResult = .success(makeTextResponse())

        let request = AIRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [
                AIMessage(role: .user, text: "Weather?"),
                AIMessage(role: .assistant, content: [
                    .toolCall(AIToolCall(
                        id: "tu_1", name: "get_weather",
                        arguments: .object(["city": "Paris"]),
                    )),
                ]),
                AIMessage(role: .user, content: [
                    .toolResult(AIToolResult(
                        toolCallId: "tu_1", content: "72°F and sunny",
                    )),
                ]),
            ],
        )

        _ = try await provider.sendMessage(request)

        let mapped = try #require(mockClient.lastSendRequest)
        #expect(mapped.messages.count == 3)
        let toolResultMsg = mapped.messages[2]
        #expect(toolResultMsg.role == .user)
        if case let .toolResult(toolUseId, content, isError) = toolResultMsg.content[0] {
            #expect(toolUseId == "tu_1")
            #expect(content == "72°F and sunny")
            #expect(isError == false)
        } else {
            Issue.record("Expected toolResult content block")
        }
    }

    // MARK: - Helpers

    private func makeTextResponse() -> MessageResponse {
        MessageResponse(
            id: "msg_123",
            content: [.text(TextBlock(text: "Hello there!"))],
            model: "claude-sonnet-4-6",
            stopReason: .endTurn,
            usage: Usage(inputTokens: 10, outputTokens: 5),
        )
    }
}

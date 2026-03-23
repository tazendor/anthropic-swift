@testable import TazendorAnthropic
import Foundation
import TazendorAI
import Testing

@Suite
struct AnthropicAIProviderTests {
    private let mockClient = MockAnthropicClient()

    private var provider: AnthropicAIProvider {
        AnthropicAIProvider(client: mockClient)
    }

    // MARK: - Provider Identity

    @Test
    func test_providerID_returnsAnthropic() {
        #expect(provider.providerID == "anthropic")
    }

    @Test
    func test_capabilities_includesExpectedSet() {
        let caps = provider.capabilities
        #expect(caps.contains(.textGeneration))
        #expect(caps.contains(.streaming))
        #expect(caps.contains(.toolUse))
        #expect(caps.contains(.vision))
        #expect(caps.contains(.thinking))
    }

    // MARK: - sendMessage Request Mapping

    @Test
    func test_sendMessage_simpleText_mapsRequestCorrectly() async throws {
        mockClient.sendResult = .success(makeTextResponse())

        let request = AIRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [AIMessage(role: .user, text: "Hello")]
        )

        _ = try await provider.sendMessage(request)

        let mapped = try #require(mockClient.lastSendRequest)
        #expect(mapped.model == "claude-sonnet-4-6")
        #expect(mapped.maxTokens == 1024)
        #expect(mapped.messages.count == 1)
        #expect(mapped.messages[0].role == .user)
    }

    @Test
    func test_sendMessage_withSystemPrompt_mapsToSystem() async throws {
        mockClient.sendResult = .success(makeTextResponse())

        let request = AIRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [AIMessage(role: .user, text: "Hi")],
            systemPrompt: "You are helpful."
        )

        _ = try await provider.sendMessage(request)

        let mapped = try #require(mockClient.lastSendRequest)
        #expect(mapped.system == .text("You are helpful."))
    }

    @Test
    func test_sendMessage_withTools_passesToolDefinitions() async throws {
        mockClient.sendResult = .success(makeTextResponse())

        let tool = ToolDefinition(
            name: "get_weather",
            description: "Get weather",
            inputSchema: ToolInputSchema(
                properties: ["city": .object(["type": "string"])],
                required: ["city"]
            )
        )

        let request = AIRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [AIMessage(role: .user, text: "Weather?")],
            tools: [tool]
        )

        _ = try await provider.sendMessage(request)

        let mapped = try #require(mockClient.lastSendRequest)
        #expect(mapped.tools?.count == 1)
        #expect(mapped.tools?[0].name == "get_weather")
    }

    @Test
    func test_sendMessage_withThinkingOption_mapsToThinkingConfig() async throws {
        mockClient.sendResult = .success(makeTextResponse())

        let request = AIRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 16384,
            messages: [AIMessage(role: .user, text: "Think")],
            options: [.anthropicThinkingBudget: .number(10000)]
        )

        _ = try await provider.sendMessage(request)

        let mapped = try #require(mockClient.lastSendRequest)
        #expect(mapped.thinking == .enabled(budgetTokens: 10000))
    }

    @Test
    func test_sendMessage_withProviderOptions_mapsCorrectly() async throws {
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
            ]
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
    func test_sendMessage_textResponse_mapsToAIResponse() async throws {
        mockClient.sendResult = .success(makeTextResponse())

        let request = AIRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [AIMessage(role: .user, text: "Hi")]
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
    func test_sendMessage_toolUseResponse_mapsToToolCall() async throws {
        let toolUseResponse = MessageResponse(
            id: "msg_456",
            content: [
                .toolUse(
                    ToolUseBlock(
                        id: "tu_1",
                        name: "get_weather",
                        input: .object(["city": "Paris"])
                    )
                ),
            ],
            model: "claude-sonnet-4-6",
            stopReason: .toolUse,
            usage: Usage(inputTokens: 20, outputTokens: 15)
        )
        mockClient.sendResult = .success(toolUseResponse)

        let request = AIRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [AIMessage(role: .user, text: "Weather?")]
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
    func test_sendMessage_allStopReasons_mapCorrectly() async throws {
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
                stopReason: anthropicReason
            )
            mockClient.sendResult = .success(response)

            let request = AIRequest(
                model: "claude-sonnet-4-6",
                maxTokens: 1024,
                messages: [AIMessage(role: .user, text: "Hi")]
            )

            let aiResponse = try await provider.sendMessage(request)
            #expect(aiResponse.stopReason == expectedReason)
        }
    }

    @Test
    func test_sendMessage_thinkingBlocks_areSkipped() async throws {
        let response = MessageResponse(
            id: "msg_1",
            content: [
                .thinking(ThinkingBlock(thinking: "hmm", signature: "sig")),
                .text(TextBlock(text: "answer")),
            ],
            model: "claude-sonnet-4-6",
            stopReason: .endTurn
        )
        mockClient.sendResult = .success(response)

        let request = AIRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [AIMessage(role: .user, text: "Think")]
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
    func test_sendMessage_apiError_mapsToAIError() async throws {
        let apiResponse = APIErrorResponse(
            type: "error",
            error: .init(type: "invalid_request_error", message: "bad model")
        )
        mockClient.sendResult = .failure(
            .apiError(statusCode: 400, response: apiResponse)
        )

        let request = AIRequest(
            model: "bad-model",
            maxTokens: 1024,
            messages: [AIMessage(role: .user, text: "Hi")]
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

    // MARK: - streamMessage

    @Test
    func test_streamMessage_textDeltas_yieldsTextEvents() async throws {
        mockClient.streamEvents = [
            .messageStart(makeTextResponse(content: [])),
            .contentBlockStart(
                index: 0,
                contentBlock: .text(TextBlock(text: ""))
            ),
            .contentBlockDelta(
                index: 0,
                delta: .textDelta(text: "Hello")
            ),
            .contentBlockDelta(
                index: 0,
                delta: .textDelta(text: " world")
            ),
            .contentBlockStop(index: 0),
            .messageDelta(
                MessageDeltaPayload(
                    delta: .init(
                        stopReason: .endTurn,
                        stopSequence: nil
                    ),
                    usage: .init(outputTokens: 2)
                )
            ),
            .messageStop,
        ]

        let request = AIRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [AIMessage(role: .user, text: "Hi")]
        )

        let stream = try await provider.streamMessage(request)
        var events: [AIStreamEvent] = []
        for try await event in stream {
            events.append(event)
        }

        // Should have: textDelta("Hello"), textDelta(" world"), done
        #expect(events.count == 3)
        if case let .textDelta(text) = events[0] {
            #expect(text == "Hello")
        } else {
            Issue.record("Expected textDelta")
        }
        if case let .textDelta(text) = events[1] {
            #expect(text == " world")
        } else {
            Issue.record("Expected textDelta")
        }
        if case let .done(response) = events[2] {
            #expect(response.stopReason == .endTurn)
            if case let .text(text) = response.content[0] {
                #expect(text == "Hello world")
            }
        } else {
            Issue.record("Expected done event")
        }
    }

    @Test
    func test_streamMessage_toolUse_yieldsToolCallEvents() async throws {
        mockClient.streamEvents = [
            .messageStart(makeTextResponse(content: [])),
            .contentBlockStart(
                index: 0,
                contentBlock: .toolUse(
                    ToolUseBlock(
                        id: "tu_1",
                        name: "get_weather",
                        input: .object([:])
                    )
                )
            ),
            .contentBlockDelta(
                index: 0,
                delta: .inputJsonDelta(partialJson: "{\"city\":")
            ),
            .contentBlockDelta(
                index: 0,
                delta: .inputJsonDelta(partialJson: "\"Paris\"}")
            ),
            .contentBlockStop(index: 0),
            .messageDelta(
                MessageDeltaPayload(
                    delta: .init(
                        stopReason: .toolUse,
                        stopSequence: nil
                    ),
                    usage: nil
                )
            ),
            .messageStop,
        ]

        let request = AIRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [AIMessage(role: .user, text: "Weather?")]
        )

        let stream = try await provider.streamMessage(request)
        var events: [AIStreamEvent] = []
        for try await event in stream {
            events.append(event)
        }

        // toolCallStart, toolCallDelta x2, done
        #expect(events.count == 4)
        if case let .toolCallStart(id, name) = events[0] {
            #expect(id == "tu_1")
            #expect(name == "get_weather")
        } else {
            Issue.record("Expected toolCallStart")
        }
        if case let .toolCallDelta(id, fragment) = events[1] {
            #expect(id == "tu_1")
            #expect(fragment == "{\"city\":")
        } else {
            Issue.record("Expected toolCallDelta")
        }
    }

    // MARK: - listModels

    @Test
    func test_listModels_mapsModelInfoCorrectly() async throws {
        let modelInfo = ModelInfo(
            id: "claude-sonnet-4-6",
            type: "model",
            displayName: "Claude Sonnet 4.6",
            createdAt: "2025-05-01T00:00:00Z",
            maxInputTokens: 200_000,
            maxTokens: 8192,
            capabilities: ModelCapabilities(
                batch: nil,
                citations: nil,
                codeExecution: nil,
                imageInput: CapabilitySupport(supported: true),
                pdfInput: nil,
                structuredOutputs: CapabilitySupport(supported: true),
                thinking: ThinkingCapability(
                    supported: true,
                    types: nil
                ),
                effort: nil
            )
        )

        mockClient.listResult = .success(
            ModelListResponse(
                data: [modelInfo],
                hasMore: false,
                firstId: modelInfo.id,
                lastId: modelInfo.id
            )
        )

        let models = try await provider.listModels()

        #expect(models.count == 1)
        let model = models[0]
        #expect(model.id == "claude-sonnet-4-6")
        #expect(model.displayName == "Claude Sonnet 4.6")
        #expect(model.provider == "anthropic")
        #expect(model.contextWindow == 200_000)
        #expect(model.maxOutputTokens == 8192)
        #expect(model.capabilities.contains(.vision))
        #expect(model.capabilities.contains(.thinking))
        #expect(model.capabilities.contains(.jsonMode))
        #expect(model.capabilities.contains(.toolUse))
    }

    // MARK: - Content Part Mapping

    @Test
    func test_sendMessage_toolResultMessage_mapsCorrectly() async throws {
        mockClient.sendResult = .success(makeTextResponse())

        let request = AIRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [
                AIMessage(role: .user, text: "Weather?"),
                AIMessage(role: .assistant, content: [
                    .toolCall(
                        AIToolCall(
                            id: "tu_1",
                            name: "get_weather",
                            arguments: .object(["city": "Paris"])
                        )
                    ),
                ]),
                AIMessage(role: .user, content: [
                    .toolResult(
                        AIToolResult(
                            toolCallId: "tu_1",
                            content: "72°F and sunny"
                        )
                    ),
                ]),
            ]
        )

        _ = try await provider.sendMessage(request)

        let mapped = try #require(mockClient.lastSendRequest)
        #expect(mapped.messages.count == 3)

        // Check tool result mapping
        let toolResultMsg = mapped.messages[2]
        #expect(toolResultMsg.role == .user)
        if case let .toolResult(toolUseId, content, isError) =
            toolResultMsg.content[0]
        {
            #expect(toolUseId == "tu_1")
            #expect(content == "72°F and sunny")
            #expect(isError == false)
        } else {
            Issue.record("Expected toolResult content block")
        }
    }

    // MARK: - Helpers

    private func makeTextResponse(
        content: [ContentBlock]? = nil
    ) -> MessageResponse {
        MessageResponse(
            id: "msg_123",
            content: content ?? [.text(TextBlock(text: "Hello there!"))],
            model: "claude-sonnet-4-6",
            stopReason: .endTurn,
            usage: Usage(inputTokens: 10, outputTokens: 5)
        )
    }
}

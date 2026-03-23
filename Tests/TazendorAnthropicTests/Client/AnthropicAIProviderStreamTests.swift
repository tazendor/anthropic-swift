import Foundation
import TazendorAI
@testable import TazendorAnthropic
import Testing

struct AnthropicAIProviderStreamTests {
    private let mockClient = MockAnthropicClient()

    private var provider: AnthropicAIProvider {
        AnthropicAIProvider(client: mockClient)
    }

    // MARK: - streamMessage

    @Test
    func streamMessage_textDeltas_yieldsTextEvents() async throws {
        mockClient.streamEvents = makeTextStreamEvents()

        let stream = try await provider.streamMessage(makeSimpleRequest())
        var events: [AIStreamEvent] = []
        for try await event in stream {
            events.append(event)
        }

        #expect(events.count == 3)
        if case let .textDelta(text) = events[0] { #expect(text == "Hello") }
        if case let .textDelta(text) = events[1] { #expect(text == " world") }
        if case let .done(response) = events[2] {
            #expect(response.stopReason == .endTurn)
            if case let .text(text) = response.content[0] {
                #expect(text == "Hello world")
            }
        }
    }

    @Test
    func streamMessage_toolUse_yieldsToolCallEvents() async throws {
        mockClient.streamEvents = makeToolStreamEvents()

        let stream = try await provider.streamMessage(makeSimpleRequest())
        var events: [AIStreamEvent] = []
        for try await event in stream {
            events.append(event)
        }

        #expect(events.count == 4)
        if case let .toolCallStart(id, name) = events[0] {
            #expect(id == "tu_1")
            #expect(name == "get_weather")
        }
        if case let .toolCallDelta(id, fragment) = events[1] {
            #expect(id == "tu_1")
            #expect(fragment == "{\"city\":")
        }
    }

    // MARK: - listModels

    @Test
    func listModels_mapsModelInfoCorrectly() async throws {
        mockClient.listResult = .success(makeModelListResponse())

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

    // MARK: - Helpers

    private func makeSimpleRequest() -> AIRequest {
        AIRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [AIMessage(role: .user, text: "Hi")],
        )
    }

    private func makeEmptyResponse() -> MessageResponse {
        MessageResponse(
            id: "msg_123",
            content: [],
            model: "claude-sonnet-4-6",
            stopReason: .endTurn,
            usage: Usage(inputTokens: 10, outputTokens: 5),
        )
    }

    private func makeTextStreamEvents() -> [StreamEvent] {
        [
            .messageStart(makeEmptyResponse()),
            .contentBlockStart(index: 0, contentBlock: .text(TextBlock(text: ""))),
            .contentBlockDelta(index: 0, delta: .textDelta(text: "Hello")),
            .contentBlockDelta(index: 0, delta: .textDelta(text: " world")),
            .contentBlockStop(index: 0),
            .messageDelta(
                MessageDeltaPayload(
                    delta: .init(stopReason: .endTurn, stopSequence: nil),
                    usage: .init(outputTokens: 2),
                ),
            ),
            .messageStop,
        ]
    }

    private func makeToolStreamEvents() -> [StreamEvent] {
        [
            .messageStart(makeEmptyResponse()),
            .contentBlockStart(
                index: 0,
                contentBlock: .toolUse(
                    ToolUseBlock(id: "tu_1", name: "get_weather", input: .object([:])),
                ),
            ),
            .contentBlockDelta(index: 0, delta: .inputJsonDelta(partialJson: "{\"city\":")),
            .contentBlockDelta(index: 0, delta: .inputJsonDelta(partialJson: "\"Paris\"}")),
            .contentBlockStop(index: 0),
            .messageDelta(
                MessageDeltaPayload(
                    delta: .init(stopReason: .toolUse, stopSequence: nil),
                    usage: nil,
                ),
            ),
            .messageStop,
        ]
    }

    private func makeModelListResponse() -> ModelListResponse {
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
                thinking: ThinkingCapability(supported: true, types: nil),
                effort: nil,
            ),
        )
        return ModelListResponse(
            data: [modelInfo],
            hasMore: false,
            firstId: modelInfo.id,
            lastId: modelInfo.id,
        )
    }
}

import Foundation
import TazendorAI

/// A provider-agnostic adapter for the Anthropic Claude API.
///
/// Wraps any ``AnthropicClient`` conformance and exposes it as an
/// ``AIClient``, enabling Anthropic to be used interchangeably with
/// other LLM providers.
///
/// For Anthropic-specific features (extended thinking, cache control),
/// use the underlying ``AnthropicClient`` directly or pass options
/// via ``AIOptionKey`` constants defined in this library.
///
/// ```swift
/// let provider = AnthropicAIProvider(
///     configuration: .init(apiKey: "sk-...")
/// )
/// let response = try await provider.sendMessage(
///     AIRequest(
///         model: "claude-sonnet-4-6",
///         maxTokens: 1024,
///         messages: [AIMessage(role: .user, text: "Hello!")]
///     )
/// )
/// ```
public struct AnthropicAIProvider: AIClient {
    private let client: any AnthropicClient

    public let providerID = "anthropic"

    public let capabilities: Set<AICapability> = [
        .textGeneration, .streaming, .toolUse, .vision, .thinking,
    ]

    /// Creates a provider wrapping an existing ``AnthropicClient``.
    public init(client: any AnthropicClient) {
        self.client = client
    }

    /// Creates a provider with a default ``URLSessionAnthropicClient``.
    public init(configuration: AnthropicConfiguration) {
        client = URLSessionAnthropicClient(configuration: configuration)
    }

    // MARK: - AIClient

    public func sendMessage(
        _ request: AIRequest
    ) async throws(AIError) -> AIResponse {
        let messageRequest = mapRequest(request)
        do {
            let response = try await client.sendMessage(messageRequest)
            return mapResponse(response)
        } catch {
            throw mapError(error)
        }
    }

    public func streamMessage(
        _ request: AIRequest
    ) async throws(AIError) -> AsyncThrowingStream<AIStreamEvent, Error> {
        let messageRequest = mapRequest(request, stream: true)
        let stream: AsyncThrowingStream<StreamEvent, Error>
        do {
            stream = try await client.streamMessage(messageRequest)
        } catch {
            throw mapError(error)
        }

        return AsyncThrowingStream { continuation in
            let task = Task {
                var accumulatedContent: [AIContentPart] = []
                var responseId = ""
                var responseModel = request.model
                var currentToolId: String?
                var finalStopReason: AIStopReason?
                var finalUsage: AIUsage?

                do {
                    for try await event in stream {
                        switch event {
                        case let .messageStart(response):
                            responseId = response.id
                            responseModel = response.model

                        case let .contentBlockStart(_, contentBlock):
                            switch contentBlock {
                            case let .text(block):
                                accumulatedContent.append(.text(block.text))
                            case let .toolUse(block):
                                currentToolId = block.id
                                accumulatedContent.append(
                                    .toolCall(
                                        AIToolCall(
                                            id: block.id,
                                            name: block.name,
                                            arguments: block.input
                                        )
                                    )
                                )
                                continuation.yield(
                                    .toolCallStart(
                                        id: block.id,
                                        name: block.name
                                    )
                                )
                            case .thinking, .redactedThinking:
                                break
                            }

                        case let .contentBlockDelta(_, delta):
                            switch delta {
                            case let .textDelta(text):
                                updateLastText(
                                    &accumulatedContent,
                                    appending: text
                                )
                                continuation.yield(.textDelta(text))
                            case let .inputJsonDelta(partialJson):
                                if let toolId = currentToolId {
                                    continuation.yield(
                                        .toolCallDelta(
                                            id: toolId,
                                            argumentsFragment: partialJson
                                        )
                                    )
                                }
                            case .thinkingDelta, .signatureDelta:
                                break
                            }

                        case .contentBlockStop:
                            currentToolId = nil

                        case let .messageDelta(payload):
                            finalStopReason = payload.delta.stopReason
                                .map(mapStopReason)
                            if let deltaUsage = payload.usage {
                                finalUsage = AIUsage(
                                    inputTokens: 0,
                                    outputTokens: deltaUsage.outputTokens
                                )
                            }

                        case .messageStop:
                            let response = AIResponse(
                                id: responseId,
                                model: responseModel,
                                content: accumulatedContent,
                                stopReason: finalStopReason,
                                usage: finalUsage
                            )
                            continuation.yield(.done(response))

                        case .ping:
                            break

                        case .error:
                            break
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    public func listModels() async throws(AIError) -> [AIModelInfo] {
        do {
            let response = try await client.listModels(
                ModelListRequest()
            )
            return response.data.map(mapModelInfo)
        } catch {
            throw mapError(error)
        }
    }
}

// MARK: - Request Mapping

extension AnthropicAIProvider {
    private func mapRequest(
        _ request: AIRequest,
        stream: Bool = false
    ) -> MessageRequest {
        let messages = request.messages.map(mapMessage)

        var thinking: ThinkingConfig?
        if case let .number(budget) = request.options[.anthropicThinkingBudget] {
            thinking = .enabled(budgetTokens: Int(budget))
        }

        var topP: Double?
        if case let .number(value) = request.options[.anthropicTopP] {
            topP = value
        }

        var topK: Int?
        if case let .number(value) = request.options[.anthropicTopK] {
            topK = Int(value)
        }

        var metadata: Metadata?
        if case let .string(userId) = request.options[.anthropicUserId] {
            metadata = Metadata(userId: userId)
        }

        return MessageRequest(
            model: request.model,
            maxTokens: request.maxTokens,
            messages: messages,
            system: request.systemPrompt.map { .text($0) },
            temperature: request.temperature,
            topP: topP,
            topK: topK,
            stopSequences: request.stopSequences,
            stream: stream ? true : nil,
            tools: request.tools,
            toolChoice: request.toolChoice,
            thinking: thinking,
            metadata: metadata
        )
    }

    private func mapMessage(_ message: AIMessage) -> InputMessage {
        let blocks = message.content.map(mapContentPart)
        return InputMessage(role: mapRole(message.role), content: blocks)
    }

    private func mapRole(_ role: AIMessageRole) -> MessageRole {
        switch role {
        case .user, .system:
            .user
        case .assistant:
            .assistant
        }
    }

    private func mapContentPart(
        _ part: AIContentPart
    ) -> InputContentBlock {
        switch part {
        case let .text(text):
            .text(text)
        case let .image(source):
            if let data = source.data {
                .image(.base64(mediaType: source.mimeType, data: data))
            } else if let url = source.url {
                .image(.url(url))
            } else {
                .text("[unsupported image source]")
            }
        case let .toolCall(call):
            .toolUse(id: call.id, name: call.name, input: call.arguments)
        case let .toolResult(result):
            .toolResult(
                toolUseId: result.toolCallId,
                content: result.content,
                isError: result.isError
            )
        }
    }
}

// MARK: - Response Mapping

extension AnthropicAIProvider {
    private func mapResponse(
        _ response: MessageResponse
    ) -> AIResponse {
        let content = response.content.compactMap(mapContentBlock)
        return AIResponse(
            id: response.id,
            model: response.model,
            content: content,
            stopReason: response.stopReason.map(mapStopReason),
            usage: response.usage.map {
                AIUsage(
                    inputTokens: $0.inputTokens,
                    outputTokens: $0.outputTokens
                )
            }
        )
    }

    private func mapContentBlock(
        _ block: ContentBlock
    ) -> AIContentPart? {
        switch block {
        case let .text(textBlock):
            .text(textBlock.text)
        case let .toolUse(toolBlock):
            .toolCall(
                AIToolCall(
                    id: toolBlock.id,
                    name: toolBlock.name,
                    arguments: toolBlock.input
                )
            )
        case .thinking, .redactedThinking:
            nil
        }
    }

    private func mapStopReason(_ reason: StopReason) -> AIStopReason {
        switch reason {
        case .endTurn:
            .endTurn
        case .maxTokens:
            .maxTokens
        case .toolUse:
            .toolUse
        case .stopSequence:
            .stopSequence
        }
    }

    private func mapModelInfo(_ model: ModelInfo) -> AIModelInfo {
        var capabilities: Set<AICapability> = [.textGeneration, .streaming]

        if model.capabilities?.imageInput?.supported == true {
            capabilities.insert(.vision)
        }
        if model.capabilities?.structuredOutputs?.supported == true {
            capabilities.insert(.jsonMode)
        }
        if model.capabilities?.thinking?.supported == true {
            capabilities.insert(.thinking)
        }
        // All Anthropic models support tool use
        capabilities.insert(.toolUse)

        return AIModelInfo(
            id: model.id,
            displayName: model.displayName,
            provider: "anthropic",
            capabilities: capabilities,
            contextWindow: model.maxInputTokens,
            maxOutputTokens: model.maxTokens
        )
    }

    /// Updates the last text content part by appending a delta.
    private func updateLastText(
        _ content: inout [AIContentPart],
        appending delta: String
    ) {
        guard let lastIndex = content.indices.last,
              case let .text(existing) = content[lastIndex]
        else { return }
        content[lastIndex] = .text(existing + delta)
    }
}

// MARK: - Error Mapping

extension AnthropicAIProvider {
    private func mapError(_ error: AnthropicError) -> AIError {
        switch error {
        case let .apiError(statusCode, response):
            .apiError(
                statusCode: statusCode,
                message: response.error.message
            )
        case let .networkError(underlying):
            .networkError(underlying: underlying)
        case let .decodingError(underlying):
            .decodingError(underlying: underlying)
        case .streamError:
            .providerError(provider: "anthropic", underlying: error)
        case let .invalidRequest(reason):
            .invalidRequest(reason: reason)
        }
    }
}

@testable import TazendorAnthropic
import Foundation
import TazendorAI

/// A mock ``AnthropicClient`` for testing the ``AnthropicAIProvider``
/// mapping layer in isolation.
final class MockAnthropicClient: AnthropicClient, @unchecked Sendable {
    /// The most recent request passed to ``sendMessage``.
    var lastSendRequest: MessageRequest?

    /// The most recent request passed to ``streamMessage``.
    var lastStreamRequest: MessageRequest?

    /// The most recent request passed to ``listModels``.
    var lastListRequest: ModelListRequest?

    /// The response to return from ``sendMessage``.
    var sendResult: Result<MessageResponse, AnthropicError> = .failure(
        .invalidRequest(reason: "no response configured")
    )

    /// The stream to return from ``streamMessage``.
    var streamEvents: [StreamEvent] = []

    /// The error to throw from ``streamMessage``, if any.
    var streamError: AnthropicError?

    /// The response to return from ``listModels``.
    var listResult: Result<ModelListResponse, AnthropicError> = .failure(
        .invalidRequest(reason: "no response configured")
    )

    /// The response to return from ``retrieveModel``.
    var retrieveResult: Result<ModelInfo, AnthropicError> = .failure(
        .invalidRequest(reason: "no response configured")
    )

    func sendMessage(
        _ request: MessageRequest
    ) async throws(AnthropicError) -> MessageResponse {
        lastSendRequest = request
        switch sendResult {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }

    func streamMessage(
        _ request: MessageRequest
    ) async throws(AnthropicError) -> AsyncThrowingStream<StreamEvent, Error> {
        lastStreamRequest = request
        if let error = streamError {
            throw error
        }
        let events = streamEvents
        return AsyncThrowingStream { continuation in
            for event in events {
                continuation.yield(event)
            }
            continuation.finish()
        }
    }

    func listModels(
        _ request: ModelListRequest
    ) async throws(AnthropicError) -> ModelListResponse {
        lastListRequest = request
        switch listResult {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }

    func retrieveModel(
        id: String
    ) async throws(AnthropicError) -> ModelInfo {
        switch retrieveResult {
        case let .success(model):
            return model
        case let .failure(error):
            throw error
        }
    }
}

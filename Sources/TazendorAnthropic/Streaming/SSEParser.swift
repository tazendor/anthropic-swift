import Foundation
import TazendorAI

/// Parses Server-Sent Events from a byte stream into typed `StreamEvent`s.
///
/// SSE format:
/// ```
/// event: message_start
/// data: {"type": "message_start", ...}
///
/// ```
/// Each event is terminated by a blank line. The `event:` field names
/// the event type, and `data:` lines (possibly multiple) contain the
/// JSON payload.
enum SSEParser {
    /// Parses an async sequence of lines into stream events.
    ///
    /// Delegates raw SSE line parsing to ``SSELineParser`` from TazendorAI,
    /// then deserializes each event's JSON payload into typed ``StreamEvent``s.
    ///
    /// - Parameter lines: An `AsyncLineSequence` from `URLSession.bytes`.
    /// - Returns: An `AsyncThrowingStream` yielding parsed `StreamEvent`s.
    static func parse<S: AsyncSequence & Sendable>(
        lines: S,
    ) -> AsyncThrowingStream<StreamEvent, Error>
        where S.Element == String
    {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let rawEvents = SSELineParser.parse(lines: lines)
                    for try await rawEvent in rawEvents {
                        guard let eventType = rawEvent.event,
                              !rawEvent.data.isEmpty
                        else { continue }
                        let data = Data(rawEvent.data.utf8)
                        if let event = try parseEvent(
                            type: eventType,
                            data: data,
                        ) {
                            continuation.yield(event)
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

    /// Decodes a single SSE event from its type string and JSON data.
    private static func parseEvent(
        type: String,
        data: Data,
    ) throws -> StreamEvent? {
        switch type {
        case "message_start":
            let payload = try JSONCoders.decoder.decode(
                MessageStartPayload.self,
                from: data,
            )
            return .messageStart(payload.message)

        case "content_block_start":
            let payload = try JSONCoders.decoder.decode(
                ContentBlockStartPayload.self,
                from: data,
            )
            return .contentBlockStart(
                index: payload.index,
                contentBlock: payload.contentBlock,
            )

        case "content_block_delta":
            let payload = try JSONCoders.decoder.decode(
                ContentBlockDeltaPayload.self,
                from: data,
            )
            return .contentBlockDelta(
                index: payload.index,
                delta: payload.delta,
            )

        case "content_block_stop":
            let payload = try JSONCoders.decoder.decode(
                ContentBlockStopPayload.self,
                from: data,
            )
            return .contentBlockStop(index: payload.index)

        case "message_delta":
            let payload = try JSONCoders.decoder.decode(
                MessageDeltaPayload.self,
                from: data,
            )
            return .messageDelta(payload)

        case "message_stop":
            return .messageStop

        case "ping":
            return .ping

        case "error":
            let errorResponse = try JSONCoders.decoder.decode(
                APIErrorResponse.self,
                from: data,
            )
            return .error(errorResponse)

        default:
            // Unknown event types are silently ignored per SSE spec
            return nil
        }
    }
}

// MARK: - SSE Payload Types

/// Internal payload for `message_start` events.
private struct MessageStartPayload: Codable {
    let message: MessageResponse
}

/// Internal payload for `content_block_start` events.
private struct ContentBlockStartPayload: Codable {
    let index: Int
    let contentBlock: ContentBlock
}

/// Internal payload for `content_block_delta` events.
private struct ContentBlockDeltaPayload: Codable {
    let index: Int
    let delta: Delta
}

/// Internal payload for `content_block_stop` events.
private struct ContentBlockStopPayload: Codable {
    let index: Int
}

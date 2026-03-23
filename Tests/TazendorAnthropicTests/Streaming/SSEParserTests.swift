import Foundation
@testable import TazendorAnthropic
import Testing

/// Tests for the SSE line parser.
struct SSEParserTests {
    /// Creates an async line sequence from raw SSE text.
    private func makeLines(
        _ text: String,
    ) -> AsyncThrowingStream<String, Error> {
        let lines = text.components(separatedBy: "\n")
        return AsyncThrowingStream { continuation in
            for line in lines {
                continuation.yield(line)
            }
            continuation.finish()
        }
    }

    /// Parses SSE text and collects all events into an array.
    private func collectEvents(
        from sseText: String,
    ) async throws -> [StreamEvent] {
        let lines = makeLines(sseText)
        let stream = SSEParser.parse(lines: lines)
        var events: [StreamEvent] = []
        for try await event in stream {
            events.append(event)
        }
        return events
    }

    // swiftlint:disable line_length
    @Test("Parses a simple text streaming sequence")
    func parse_whenSimpleTextStream_yieldsCorrectEvents() async throws {
        let sseText = """
        event: message_start
        data: {"type": "message_start", "message": {"id": "msg_01", "type": "message", "role": "assistant", "content": [], "model": "claude-sonnet-4-6", "stop_reason": null, "stop_sequence": null, "usage": {"input_tokens": 25, "output_tokens": 1}}}

        event: content_block_start
        data: {"type": "content_block_start", "index": 0, "content_block": {"type": "text", "text": ""}}

        event: content_block_delta
        data: {"type": "content_block_delta", "index": 0, "delta": {"type": "text_delta", "text": "Hello"}}

        event: content_block_stop
        data: {"type": "content_block_stop", "index": 0}

        event: message_delta
        data: {"type": "message_delta", "delta": {"stop_reason": "end_turn", "stop_sequence": null}, "usage": {"output_tokens": 15}}

        event: message_stop
        data: {"type": "message_stop"}

        """

        let events = try await collectEvents(from: sseText)
        #expect(events.count == 6)

        guard case let .messageStart(msg) = events[0] else {
            Issue.record("Expected messageStart"); return
        }
        #expect(msg.id == "msg_01")

        guard case let .contentBlockStart(idx, _) = events[1] else {
            Issue.record("Expected contentBlockStart"); return
        }
        #expect(idx == 0)

        guard case let .contentBlockDelta(_, delta) = events[2] else {
            Issue.record("Expected contentBlockDelta"); return
        }
        guard case let .textDelta(text) = delta else {
            Issue.record("Expected textDelta"); return
        }
        #expect(text == "Hello")

        guard case let .contentBlockStop(stopIdx) = events[3] else {
            Issue.record("Expected contentBlockStop"); return
        }
        #expect(stopIdx == 0)

        guard case .messageDelta = events[4] else {
            Issue.record("Expected messageDelta"); return
        }

        guard case .messageStop = events[5] else {
            Issue.record("Expected messageStop"); return
        }
    }

    // swiftlint:enable line_length

    @Test("Parses ping events")
    func parse_whenPingEvent_yieldsPing() async throws {
        let sseText = """
        event: ping
        data: {"type": "ping"}

        """

        let lines = makeLines(sseText)
        let stream = SSEParser.parse(lines: lines)
        var events: [StreamEvent] = []

        for try await event in stream {
            events.append(event)
        }

        #expect(events.count == 1)
        guard case .ping = events[0] else {
            Issue.record("Expected ping")
            return
        }
    }

    // swiftlint:disable line_length
    @Test("Parses thinking delta events")
    func parse_whenThinkingDelta_yieldsThinkingDelta() async throws {
        let sseText = """
        event: content_block_start
        data: {"type": "content_block_start", "index": 0, "content_block": {"type": "thinking", "thinking": "", "signature": ""}}

        event: content_block_delta
        data: {"type": "content_block_delta", "index": 0, "delta": {"type": "thinking_delta", "thinking": "Let me think..."}}

        event: content_block_delta
        data: {"type": "content_block_delta", "index": 0, "delta": {"type": "signature_delta", "signature": "abc123sig"}}

        event: content_block_stop
        data: {"type": "content_block_stop", "index": 0}

        """

        let events = try await collectEvents(from: sseText)
        #expect(events.count == 4)

        guard case let .contentBlockDelta(_, delta1) = events[1] else {
            Issue.record("Expected contentBlockDelta"); return
        }
        guard case let .thinkingDelta(thinking) = delta1 else {
            Issue.record("Expected thinkingDelta"); return
        }
        #expect(thinking == "Let me think...")

        guard case let .contentBlockDelta(_, delta2) = events[2] else {
            Issue.record("Expected contentBlockDelta"); return
        }
        guard case let .signatureDelta(sig) = delta2 else {
            Issue.record("Expected signatureDelta"); return
        }
        #expect(sig == "abc123sig")
    }

    @Test("Parses tool use input_json_delta")
    func parse_whenInputJsonDelta_yieldsInputJsonDelta() async throws {
        let sseText = """
        event: content_block_start
        data: {"type": "content_block_start", "index": 1, "content_block": {"type": "tool_use", "id": "toolu_01", "name": "get_weather", "input": {}}}

        event: content_block_delta
        data: {"type": "content_block_delta", "index": 1, "delta": {"type": "input_json_delta", "partial_json": "{\\"location\\":"}}

        event: content_block_delta
        data: {"type": "content_block_delta", "index": 1, "delta": {"type": "input_json_delta", "partial_json": " \\"NYC\\"}"}}

        event: content_block_stop
        data: {"type": "content_block_stop", "index": 1}

        """

        let events = try await collectEvents(from: sseText)
        #expect(events.count == 4)

        guard case let .contentBlockDelta(_, delta) = events[1] else {
            Issue.record("Expected contentBlockDelta"); return
        }
        guard case let .inputJsonDelta(json) = delta else {
            Issue.record("Expected inputJsonDelta"); return
        }
        #expect(json == "{\"location\":")
    }

    // swiftlint:enable line_length

    @Test("Ignores unknown event types gracefully")
    func parse_whenUnknownEventType_skipsEvent() async throws {
        let sseText = """
        event: unknown_future_event
        data: {"type": "unknown_future_event", "foo": "bar"}

        event: message_stop
        data: {"type": "message_stop"}

        """

        let lines = makeLines(sseText)
        let stream = SSEParser.parse(lines: lines)
        var events: [StreamEvent] = []

        for try await event in stream {
            events.append(event)
        }

        #expect(events.count == 1)
        guard case .messageStop = events[0] else {
            Issue.record("Expected messageStop")
            return
        }
    }

    @Test("Parses error events from stream")
    func parse_whenErrorEvent_yieldsError() async throws {
        let sseText = """
        event: error
        data: {"type": "error", "error": {"type": "overloaded_error", "message": "Overloaded"}}

        """

        let lines = makeLines(sseText)
        let stream = SSEParser.parse(lines: lines)
        var events: [StreamEvent] = []

        for try await event in stream {
            events.append(event)
        }

        #expect(events.count == 1)
        guard case let .error(errResponse) = events[0] else {
            Issue.record("Expected error event")
            return
        }
        #expect(errResponse.error.type == "overloaded_error")
    }
}

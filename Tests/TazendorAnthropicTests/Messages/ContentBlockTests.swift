@testable import TazendorAnthropic
import Foundation
import TazendorAI
import Testing

/// Tests for ContentBlock discriminated union encoding/decoding.
struct ContentBlockTests {
    @Test("Decode text content block from JSON")
    func decodeContentBlock_whenTypeIsText_returnsTextBlock() throws {
        let json = """
        {"type": "text", "text": "Hello world"}
        """
        let data = Data(json.utf8)
        let block = try JSONCoders.decoder.decode(
            ContentBlock.self,
            from: data,
        )

        guard case let .text(textBlock) = block else {
            #expect(Bool(false), "Expected text block")
            return
        }
        #expect(textBlock.text == "Hello world")
    }

    @Test("Decode tool_use content block from JSON")
    func decodeContentBlock_whenTypeIsToolUse_returnsToolUseBlock()
        throws
    {
        let json = """
        {
            "type": "tool_use",
            "id": "toolu_123",
            "name": "get_weather",
            "input": {"location": "NYC"}
        }
        """
        let data = Data(json.utf8)
        let block = try JSONCoders.decoder.decode(
            ContentBlock.self,
            from: data,
        )

        guard case let .toolUse(toolBlock) = block else {
            #expect(Bool(false), "Expected tool_use block")
            return
        }
        #expect(toolBlock.id == "toolu_123")
        #expect(toolBlock.name == "get_weather")
        #expect(
            toolBlock.input == .object(["location": .string("NYC")]),
        )
    }

    @Test("Decode thinking content block from JSON")
    func decodeContentBlock_whenTypeIsThinking_returnsThinkingBlock()
        throws
    {
        let json = """
        {
            "type": "thinking",
            "thinking": "Let me reason about this...",
            "signature": "abc123"
        }
        """
        let data = Data(json.utf8)
        let block = try JSONCoders.decoder.decode(
            ContentBlock.self,
            from: data,
        )

        guard case let .thinking(thinkBlock) = block else {
            #expect(Bool(false), "Expected thinking block")
            return
        }
        #expect(thinkBlock.thinking == "Let me reason about this...")
        #expect(thinkBlock.signature == "abc123")
    }

    @Test("Decode redacted_thinking content block from JSON")
    func decodeContentBlock_whenTypeIsRedacted_returnsRedactedBlock()
        throws
    {
        let json = """
        {"type": "redacted_thinking", "data": "opaque_data_here"}
        """
        let data = Data(json.utf8)
        let block = try JSONCoders.decoder.decode(
            ContentBlock.self,
            from: data,
        )

        guard case let .redactedThinking(redacted) = block else {
            #expect(Bool(false), "Expected redacted_thinking block")
            return
        }
        #expect(redacted.data == "opaque_data_here")
    }

    @Test("Decode unknown content block type throws error")
    func decodeContentBlock_whenTypeIsUnknown_throwsError() {
        let json = """
        {"type": "unknown_type", "data": "test"}
        """
        let data = Data(json.utf8)
        #expect(throws: DecodingError.self) {
            try JSONCoders.decoder.decode(ContentBlock.self, from: data)
        }
    }

    @Test("ContentBlock text round-trips through encode/decode")
    func contentBlock_text_roundTrip() throws {
        let original = ContentBlock.text(TextBlock(text: "Hello"))
        let data = try JSONCoders.encoder.encode(original)
        let decoded = try JSONCoders.decoder.decode(
            ContentBlock.self,
            from: data,
        )
        #expect(decoded == original)
    }

    @Test("ContentBlock toolUse round-trips through encode/decode")
    func contentBlock_toolUse_roundTrip() throws {
        let original = ContentBlock.toolUse(ToolUseBlock(
            id: "toolu_123",
            name: "test_tool",
            input: .object(["key": .string("value")]),
        ))
        let data = try JSONCoders.encoder.encode(original)
        let decoded = try JSONCoders.decoder.decode(
            ContentBlock.self,
            from: data,
        )
        #expect(decoded == original)
    }
}

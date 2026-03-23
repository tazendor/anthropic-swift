@testable import TazendorAnthropic
import Foundation
import TazendorAI
import Testing

/// Tests that all Codable model types survive encode→decode round-trips
/// and decode correctly from API fixture JSON.
struct CodableRoundTripTests {
    // MARK: - Fixture Loading

    private func loadFixture(_ name: String) throws -> Data {
        let url = Bundle.module.url(
            forResource: name,
            withExtension: "json",
            subdirectory: "Fixtures",
        )
        guard let url else {
            throw FixtureError.notFound(name)
        }
        return try Data(contentsOf: url)
    }

    private enum FixtureError: Error {
        case notFound(String)
    }

    // MARK: - MessageResponse

    @Test("Decode basic message response from fixture JSON")
    func decodeMessageResponse_whenBasicFixture_decodesCorrectly()
        throws
    {
        let data = try loadFixture("message_response")
        let response = try JSONCoders.decoder.decode(
            MessageResponse.self,
            from: data,
        )

        #expect(response.id == "msg_01XFDUDYJgAACzvnptvVoYEL")
        #expect(response.type == "message")
        #expect(response.role == .assistant)
        #expect(response.model == "claude-sonnet-4-6")
        #expect(response.stopReason == .endTurn)
        #expect(response.content.count == 1)

        guard case let .text(block) = response.content.first else {
            #expect(Bool(false), "Expected text block")
            return
        }
        #expect(block.text == "Hello! How can I help you today?")
    }

    @Test("Decode tool use response from fixture JSON")
    func decodeMessageResponse_whenToolUseFixture_decodesCorrectly()
        throws
    {
        let data = try loadFixture("tool_use_response")
        let response = try JSONCoders.decoder.decode(
            MessageResponse.self,
            from: data,
        )

        #expect(response.stopReason == .toolUse)
        #expect(response.content.count == 2)

        guard case let .toolUse(toolBlock) = response.content[1] else {
            #expect(Bool(false), "Expected tool_use block")
            return
        }
        #expect(toolBlock.name == "get_weather")
        #expect(toolBlock.id == "toolu_01A09q90qw90lq917835lq9")
    }

    @Test("Decode thinking response from fixture JSON")
    func decodeMessageResponse_whenThinkingFixture_decodesCorrectly()
        throws
    {
        let data = try loadFixture("thinking_response")
        let response = try JSONCoders.decoder.decode(
            MessageResponse.self,
            from: data,
        )

        #expect(response.content.count == 2)

        guard case let .thinking(thinkBlock) = response.content[0] else {
            #expect(Bool(false), "Expected thinking block")
            return
        }
        #expect(thinkBlock.thinking.contains("Euclidean algorithm"))
        #expect(!thinkBlock.signature.isEmpty)

        guard case let .text(textBlock) = response.content[1] else {
            #expect(Bool(false), "Expected text block")
            return
        }
        #expect(textBlock.text.contains("21"))
    }

    // MARK: - APIErrorResponse

    @Test("Decode API error response from fixture JSON")
    func decodeErrorResponse_whenFixture_decodesCorrectly() throws {
        let data = try loadFixture("error_response")
        let response = try JSONCoders.decoder.decode(
            APIErrorResponse.self,
            from: data,
        )

        #expect(response.type == "error")
        #expect(response.error.type == "invalid_request_error")
        #expect(response.error.message.contains("max_tokens"))
    }

    // MARK: - ModelListResponse

    @Test("Decode model list response from fixture JSON")
    func decodeModelList_whenFixture_decodesCorrectly() throws {
        let data = try loadFixture("model_list")
        let response = try JSONCoders.decoder.decode(
            ModelListResponse.self,
            from: data,
        )

        #expect(response.data.count == 1)
        #expect(response.hasMore == false)

        let model = response.data[0]
        #expect(model.id == "claude-sonnet-4-6")
        #expect(model.displayName == "Claude Sonnet 4.6")
        #expect(model.maxInputTokens == 200_000)
        #expect(model.capabilities?.thinking?.supported == true)
    }

    // MARK: - Round-trips

    @Test("Usage round-trips through encode/decode")
    func usage_roundTrip() throws {
        let original = Usage(
            inputTokens: 100,
            outputTokens: 50,
            cacheCreationInputTokens: 10,
            cacheReadInputTokens: 5,
        )
        let data = try JSONCoders.encoder.encode(original)
        let decoded = try JSONCoders.decoder.decode(Usage.self, from: data)
        #expect(decoded == original)
    }

    @Test("ThinkingConfig enabled round-trips through encode/decode")
    func thinkingConfig_enabled_roundTrip() throws {
        let original = ThinkingConfig.enabled(budgetTokens: 10000)
        let data = try JSONCoders.encoder.encode(original)
        let decoded = try JSONCoders.decoder.decode(
            ThinkingConfig.self,
            from: data,
        )
        #expect(decoded == original)
    }

    @Test("ThinkingConfig disabled round-trips through encode/decode")
    func thinkingConfig_disabled_roundTrip() throws {
        let original = ThinkingConfig.disabled
        let data = try JSONCoders.encoder.encode(original)
        let decoded = try JSONCoders.decoder.decode(
            ThinkingConfig.self,
            from: data,
        )
        #expect(decoded == original)
    }

    @Test("ToolChoice variants round-trip through encode/decode")
    func toolChoice_roundTrip() throws {
        let cases: [ToolChoice] = [.auto, .any, .tool(name: "get_weather"), .none]

        for original in cases {
            let data = try JSONCoders.encoder.encode(original)
            let decoded = try JSONCoders.decoder.decode(
                ToolChoice.self,
                from: data,
            )
            #expect(decoded == original)
        }
    }

    @Test("SystemPrompt text round-trips through encode/decode")
    func systemPrompt_text_roundTrip() throws {
        let original = SystemPrompt.text("You are helpful.")
        let data = try JSONCoders.encoder.encode(original)
        let decoded = try JSONCoders.decoder.decode(
            SystemPrompt.self,
            from: data,
        )
        #expect(decoded == original)
    }
}

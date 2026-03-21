@testable import AnthropicKit
import Foundation
import Testing

/// Tests for AnthropicConfiguration defaults and custom values.
struct AnthropicConfigurationTests {
    @Test("Default configuration uses correct base URL and version")
    func defaults_areCorrect() {
        let config = AnthropicConfiguration(apiKey: "test-key")

        #expect(
            config.baseURL == URL(string: "https://api.anthropic.com"),
        )
        #expect(config.apiVersion == "2023-06-01")
        #expect(config.timeoutInterval == 120)
    }

    @Test("Custom configuration overrides defaults")
    func customValues_overrideDefaults() throws {
        let config = try AnthropicConfiguration(
            apiKey: "custom-key",
            baseURL: #require(URL(string: "https://test.example.com")),
            apiVersion: "2025-01-01",
            timeoutInterval: 30,
        )

        #expect(
            config.baseURL == URL(string: "https://test.example.com"),
        )
        #expect(config.apiVersion == "2025-01-01")
        #expect(config.timeoutInterval == 30)
    }
}

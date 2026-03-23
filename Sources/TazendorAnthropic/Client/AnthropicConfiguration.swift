import Foundation

/// Configuration for the Anthropic API client.
///
/// The API key is accepted at init time and held in memory only.
/// The caller is responsible for secure storage (e.g. Keychain).
/// This library never persists or logs API keys.
public struct AnthropicConfiguration: Sendable {
    /// The API key for authentication.
    public let apiKey: String

    /// The base URL for the Anthropic API.
    public let baseURL: URL

    /// The API version header value.
    public let apiVersion: String

    /// Timeout interval for requests in seconds.
    public let timeoutInterval: TimeInterval

    /// Creates a configuration with the given parameters.
    /// - Parameters:
    ///   - apiKey: Your Anthropic API key.
    ///   - baseURL: API base URL. Defaults to `https://api.anthropic.com`.
    ///   - apiVersion: API version string. Defaults to `2023-06-01`.
    ///   - timeoutInterval: Request timeout in seconds. Defaults to 120.
    public init(
        apiKey: String,
        baseURL: URL = URL(string: "https://api.anthropic.com")!,
        apiVersion: String = "2023-06-01",
        timeoutInterval: TimeInterval = 120,
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.apiVersion = apiVersion
        self.timeoutInterval = timeoutInterval
    }
}

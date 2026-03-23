/// Information about an available model.
public struct ModelInfo: Codable, Sendable, Hashable {
    /// Unique model identifier (e.g., "claude-sonnet-4-6").
    public let id: String

    /// Object type (always "model").
    public let type: String

    /// Human-readable model name.
    public let displayName: String

    /// RFC 3339 datetime when the model was released.
    public let createdAt: String

    /// Maximum input context window size in tokens.
    public let maxInputTokens: Int

    /// Maximum value for the `max_tokens` parameter.
    public let maxTokens: Int

    /// Model capabilities.
    public let capabilities: ModelCapabilities?
}

/// Token usage statistics for a message request.
public struct Usage: Codable, Sendable, Hashable {
    /// Number of input tokens consumed.
    public let inputTokens: Int

    /// Number of output tokens generated.
    public let outputTokens: Int

    /// Tokens used to create a new cache entry, if any.
    public let cacheCreationInputTokens: Int?

    /// Tokens read from an existing cache entry, if any.
    public let cacheReadInputTokens: Int?

    public init(
        inputTokens: Int,
        outputTokens: Int,
        cacheCreationInputTokens: Int? = nil,
        cacheReadInputTokens: Int? = nil,
    ) {
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheCreationInputTokens = cacheCreationInputTokens
        self.cacheReadInputTokens = cacheReadInputTokens
    }
}

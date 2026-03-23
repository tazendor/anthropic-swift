/// The response from the Messages API.
///
/// Contains the model's generated content blocks, usage statistics,
/// and the reason generation stopped.
public struct MessageResponse: Codable, Sendable, Hashable {
    /// Unique message identifier.
    public let id: String

    /// Object type (always "message").
    public let type: String

    /// The role (always "assistant" for responses).
    public let role: MessageRole

    /// The generated content blocks.
    public let content: [ContentBlock]

    /// The model that generated this response.
    public let model: String

    /// Why the model stopped generating.
    public let stopReason: StopReason?

    /// The matched stop sequence, if applicable.
    public let stopSequence: String?

    /// Token usage statistics.
    public let usage: Usage?

    public init(
        id: String,
        type: String = "message",
        role: MessageRole = .assistant,
        content: [ContentBlock],
        model: String,
        stopReason: StopReason?,
        stopSequence: String? = nil,
        usage: Usage? = nil,
    ) {
        self.id = id
        self.type = type
        self.role = role
        self.content = content
        self.model = model
        self.stopReason = stopReason
        self.stopSequence = stopSequence
        self.usage = usage
    }
}

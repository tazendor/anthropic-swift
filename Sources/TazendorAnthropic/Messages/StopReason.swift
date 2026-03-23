/// The reason the model stopped generating tokens.
public enum StopReason: String, Codable, Sendable {
    /// The model reached a natural stopping point.
    case endTurn = "end_turn"

    /// The model hit the `max_tokens` limit.
    case maxTokens = "max_tokens"

    /// The model encountered a custom stop sequence.
    case stopSequence = "stop_sequence"

    /// The model is requesting to use a tool.
    case toolUse = "tool_use"
}

/// A thinking content block containing the model's chain-of-thought.
///
/// Only present when extended thinking is enabled. The `signature`
/// field is used to verify the integrity of the thinking content.
public struct ThinkingBlock: Codable, Sendable, Hashable {
    /// The model's internal reasoning text.
    public let thinking: String

    /// Cryptographic signature for integrity verification.
    public let signature: String

    public init(thinking: String, signature: String) {
        self.thinking = thinking
        self.signature = signature
    }
}

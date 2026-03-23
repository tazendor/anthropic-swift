/// A redacted thinking block where the model's reasoning was filtered.
///
/// Contains only opaque data; the thinking content is not available.
public struct RedactedThinkingBlock: Codable, Sendable, Hashable {
    /// Opaque data representing the redacted thinking.
    public let data: String

    public init(data: String) {
        self.data = data
    }
}

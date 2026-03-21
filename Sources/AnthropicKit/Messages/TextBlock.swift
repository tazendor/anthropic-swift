/// A text content block in a message response.
public struct TextBlock: Codable, Sendable, Hashable {
    /// The text content.
    public let text: String

    public init(text: String) {
        self.text = text
    }
}

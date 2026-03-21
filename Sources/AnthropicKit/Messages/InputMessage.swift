/// A message in the input conversation.
///
/// Messages alternate between `user` and `assistant` roles. Content
/// can be a simple string (converted to a single text block) or an
/// array of typed content blocks.
public struct InputMessage: Sendable, Hashable {
    /// The role of the message author.
    public let role: MessageRole

    /// The message content blocks.
    public let content: [InputContentBlock]

    /// Creates a message with an array of content blocks.
    public init(role: MessageRole, content: [InputContentBlock]) {
        self.role = role
        self.content = content
    }

    /// Creates a message with a single text string.
    public init(role: MessageRole, text: String) {
        self.role = role
        content = [.text(text)]
    }
}

// MARK: - Codable

extension InputMessage: Codable {
    private enum CodingKeys: String, CodingKey {
        case role
        case content
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        role = try container.decode(MessageRole.self, forKey: .role)

        // Content can be a string or an array of content blocks
        if let text = try? container.decode(String.self, forKey: .content) {
            content = [.text(text)]
        } else {
            content = try container.decode(
                [InputContentBlock].self,
                forKey: .content,
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)

        // Encode as simple string when there's a single text block
        if content.count == 1, case let .text(text) = content.first {
            try container.encode(text, forKey: .content)
        } else {
            try container.encode(content, forKey: .content)
        }
    }
}

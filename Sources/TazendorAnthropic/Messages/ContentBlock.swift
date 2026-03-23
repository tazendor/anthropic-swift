/// A content block in an assistant message response.
///
/// The API returns content as an array of typed blocks. Each block
/// has a `type` discriminator that determines its structure. This
/// enum uses custom `Codable` to dispatch on that discriminator.
public enum ContentBlock: Sendable, Hashable {
    case text(TextBlock)
    case toolUse(ToolUseBlock)
    case thinking(ThinkingBlock)
    case redactedThinking(RedactedThinkingBlock)
}

// MARK: - Codable

extension ContentBlock: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "text":
            let block = try TextBlock(from: decoder)
            self = .text(block)
        case "tool_use":
            let block = try ToolUseBlock(from: decoder)
            self = .toolUse(block)
        case "thinking":
            let block = try ThinkingBlock(from: decoder)
            self = .thinking(block)
        case "redacted_thinking":
            let block = try RedactedThinkingBlock(from: decoder)
            self = .redactedThinking(block)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown content block type: \(type)",
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .text(block):
            try container.encode("text", forKey: .type)
            try block.encode(to: encoder)
        case let .toolUse(block):
            try container.encode("tool_use", forKey: .type)
            try block.encode(to: encoder)
        case let .thinking(block):
            try container.encode("thinking", forKey: .type)
            try block.encode(to: encoder)
        case let .redactedThinking(block):
            try container.encode("redacted_thinking", forKey: .type)
            try block.encode(to: encoder)
        }
    }
}

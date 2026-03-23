import Foundation
import TazendorAI

/// A content block in a user or assistant input message.
///
/// Input content blocks differ from response content blocks — they
/// include image, document, and tool result types that are only valid
/// in request messages.
public enum InputContentBlock: Sendable, Hashable {
    case text(String)
    case image(ImageSource)
    case toolUse(id: String, name: String, input: JSONValue)
    case toolResult(toolUseId: String, content: String, isError: Bool)
}

/// The source of an image content block.
public struct ImageSource: Codable, Sendable, Hashable {
    /// Source type ("base64" or "url").
    public let type: String

    /// Media type (e.g., "image/jpeg", "image/png").
    public let mediaType: String?

    /// Base64-encoded image data (when type is "base64").
    public let data: String?

    /// Image URL (when type is "url").
    public let url: String?

    /// Creates a base64 image source.
    public static func base64(
        mediaType: String,
        data: String,
    ) -> ImageSource {
        ImageSource(
            type: "base64",
            mediaType: mediaType,
            data: data,
            url: nil,
        )
    }

    /// Creates a URL image source.
    public static func url(_ url: String) -> ImageSource {
        ImageSource(
            type: "url",
            mediaType: nil,
            data: nil,
            url: url,
        )
    }
}

// MARK: - Codable

extension InputContentBlock: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case text
        case source
        case id
        case name
        case input
        case toolUseId
        case content
        case isError
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "text":
            let text = try container.decode(String.self, forKey: .text)
            self = .text(text)
        case "image":
            let source = try container.decode(
                ImageSource.self,
                forKey: .source,
            )
            self = .image(source)
        case "tool_use":
            let id = try container.decode(String.self, forKey: .id)
            let name = try container.decode(String.self, forKey: .name)
            let input = try container.decode(JSONValue.self, forKey: .input)
            self = .toolUse(id: id, name: name, input: input)
        case "tool_result":
            let toolUseId = try container.decode(
                String.self,
                forKey: .toolUseId,
            )
            let content = try container.decodeIfPresent(
                String.self,
                forKey: .content,
            ) ?? ""
            let isError = try container.decodeIfPresent(
                Bool.self,
                forKey: .isError,
            ) ?? false
            self = .toolResult(
                toolUseId: toolUseId,
                content: content,
                isError: isError,
            )
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown input content block type: \(type)",
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .text(text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .text)
        case let .image(source):
            try container.encode("image", forKey: .type)
            try container.encode(source, forKey: .source)
        case let .toolUse(id, name, input):
            try container.encode("tool_use", forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(input, forKey: .input)
        case let .toolResult(toolUseId, content, isError):
            try container.encode("tool_result", forKey: .type)
            try container.encode(toolUseId, forKey: .toolUseId)
            try container.encode(content, forKey: .content)
            try container.encode(isError, forKey: .isError)
        }
    }
}

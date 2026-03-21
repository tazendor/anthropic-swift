/// A delta update within a streaming content block.
///
/// Each delta type corresponds to a specific content block type:
/// `textDelta` for text blocks, `inputJsonDelta` for tool use blocks,
/// and `thinkingDelta`/`signatureDelta` for thinking blocks.
public enum Delta: Sendable, Hashable {
    /// A text fragment.
    case textDelta(text: String)

    /// A fragment of JSON input for a tool use block.
    case inputJsonDelta(partialJson: String)

    /// A fragment of thinking content.
    case thinkingDelta(thinking: String)

    /// The signature for a thinking block (sent before block stop).
    case signatureDelta(signature: String)
}

// MARK: - Codable

extension Delta: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case text
        case partialJson
        case thinking
        case signature
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "text_delta":
            let text = try container.decode(String.self, forKey: .text)
            self = .textDelta(text: text)
        case "input_json_delta":
            let json = try container.decode(
                String.self,
                forKey: .partialJson,
            )
            self = .inputJsonDelta(partialJson: json)
        case "thinking_delta":
            let thinking = try container.decode(
                String.self,
                forKey: .thinking,
            )
            self = .thinkingDelta(thinking: thinking)
        case "signature_delta":
            let sig = try container.decode(
                String.self,
                forKey: .signature,
            )
            self = .signatureDelta(signature: sig)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown delta type: \(type)",
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .textDelta(text):
            try container.encode("text_delta", forKey: .type)
            try container.encode(text, forKey: .text)
        case let .inputJsonDelta(json):
            try container.encode("input_json_delta", forKey: .type)
            try container.encode(json, forKey: .partialJson)
        case let .thinkingDelta(thinking):
            try container.encode("thinking_delta", forKey: .type)
            try container.encode(thinking, forKey: .thinking)
        case let .signatureDelta(sig):
            try container.encode("signature_delta", forKey: .type)
            try container.encode(sig, forKey: .signature)
        }
    }
}

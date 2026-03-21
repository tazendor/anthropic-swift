/// Controls how the model selects tools.
public enum ToolChoice: Sendable, Hashable {
    /// The model decides whether to use a tool.
    case auto

    /// The model must use at least one tool.
    case any

    /// The model must use the specified tool.
    case tool(name: String)

    /// The model must not use any tools.
    case none
}

// MARK: - Codable

extension ToolChoice: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "auto":
            self = .auto
        case "any":
            self = .any
        case "tool":
            let name = try container.decode(String.self, forKey: .name)
            self = .tool(name: name)
        case "none":
            self = .none
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown tool choice type: \(type)",
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .auto:
            try container.encode("auto", forKey: .type)
        case .any:
            try container.encode("any", forKey: .type)
        case let .tool(name):
            try container.encode("tool", forKey: .type)
            try container.encode(name, forKey: .name)
        case .none:
            try container.encode("none", forKey: .type)
        }
    }
}

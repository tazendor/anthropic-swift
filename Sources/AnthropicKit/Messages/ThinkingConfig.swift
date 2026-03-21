/// Configuration for extended thinking (chain-of-thought reasoning).
///
/// When enabled, the model performs internal reasoning before responding.
/// The `budgetTokens` parameter sets the maximum tokens the model can
/// use for thinking. Minimum is 1,024 tokens.
public enum ThinkingConfig: Codable, Sendable, Hashable {
    /// Extended thinking is enabled with the given token budget.
    case enabled(budgetTokens: Int)

    /// Extended thinking is disabled.
    case disabled

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type
        case budgetTokens
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "enabled":
            let budget = try container.decode(
                Int.self,
                forKey: .budgetTokens,
            )
            self = .enabled(budgetTokens: budget)
        case "disabled":
            self = .disabled
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown thinking type: \(type)",
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .enabled(budgetTokens):
            try container.encode("enabled", forKey: .type)
            try container.encode(budgetTokens, forKey: .budgetTokens)
        case .disabled:
            try container.encode("disabled", forKey: .type)
        }
    }
}

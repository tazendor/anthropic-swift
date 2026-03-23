/// Capability information for a model.
///
/// Each capability indicates whether the model supports a feature.
/// The API returns a nested structure; capabilities with sub-features
/// (like thinking types or effort levels) are represented as dedicated types.
public struct ModelCapabilities: Codable, Sendable, Hashable {
    /// Whether the model supports the Batch API.
    public let batch: CapabilitySupport?

    /// Whether the model supports citation generation.
    public let citations: CapabilitySupport?

    /// Whether the model supports code execution tools.
    public let codeExecution: CapabilitySupport?

    /// Whether the model accepts image content blocks.
    public let imageInput: CapabilitySupport?

    /// Whether the model accepts PDF content blocks.
    public let pdfInput: CapabilitySupport?

    /// Whether the model supports structured output / JSON mode.
    public let structuredOutputs: CapabilitySupport?

    /// Extended thinking capability and supported configurations.
    public let thinking: ThinkingCapability?

    /// Effort (reasoning effort) support and available levels.
    public let effort: EffortCapability?
}

/// Indicates whether a capability is supported by the model.
public struct CapabilitySupport: Codable, Sendable, Hashable {
    /// Whether this capability is supported.
    public let supported: Bool
}

/// Effort (reasoning effort) capability with supported levels.
public struct EffortCapability: Codable, Sendable, Hashable {
    /// Whether effort control is supported.
    public let supported: Bool

    /// Whether the model supports low effort level.
    public let low: CapabilitySupport?

    /// Whether the model supports medium effort level.
    public let medium: CapabilitySupport?

    /// Whether the model supports high effort level.
    public let high: CapabilitySupport?

    /// Whether the model supports max effort level.
    public let max: CapabilitySupport?
}

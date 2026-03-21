/// Thinking capability information for a model.
public struct ThinkingCapability: Codable, Sendable, Hashable {
    /// Whether thinking is supported by this model.
    public let supported: Bool

    /// Supported thinking type configurations.
    public let types: ThinkingTypes?

    /// The types of thinking configurations a model supports.
    public struct ThinkingTypes: Codable, Sendable, Hashable {
        /// Whether the model supports thinking with type "enabled".
        public let enabled: CapabilitySupport?

        /// Whether the model supports thinking with type "adaptive".
        public let adaptive: CapabilitySupport?
    }
}

/// Request metadata for tracking and abuse prevention.
public struct Metadata: Codable, Sendable, Hashable {
    /// An external identifier for the user making the request.
    /// Used by Anthropic for abuse detection.
    public let userId: String?

    public init(userId: String? = nil) {
        self.userId = userId
    }
}

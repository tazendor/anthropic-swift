/// Cache control configuration for prompt caching.
public struct CacheControl: Codable, Sendable, Hashable {
    /// The cache control type (always "ephemeral").
    public let type: String

    /// Time-to-live for the cache entry.
    public let ttl: String?

    /// Creates an ephemeral cache control with optional TTL.
    /// - Parameter ttl: Cache duration ("5m" or "1h"). Defaults to "5m".
    public init(ttl: String? = nil) {
        type = "ephemeral"
        self.ttl = ttl
    }
}

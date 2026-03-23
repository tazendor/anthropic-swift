/// Parameters for listing available models.
public struct ModelListRequest: Sendable {
    /// Cursor for forward pagination. Returns results after this ID.
    public let afterId: String?

    /// Cursor for backward pagination. Returns results before this ID.
    public let beforeId: String?

    /// Number of results per page (1–1000, default 20).
    public let limit: Int?

    public init(
        afterId: String? = nil,
        beforeId: String? = nil,
        limit: Int? = nil,
    ) {
        self.afterId = afterId
        self.beforeId = beforeId
        self.limit = limit
    }
}

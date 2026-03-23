/// Response from the model listing endpoint.
public struct ModelListResponse: Codable, Sendable, Hashable {
    /// The list of models.
    public let data: [ModelInfo]

    /// Whether there are more results available.
    public let hasMore: Bool

    /// First model ID in this page (use as `beforeId` for previous page).
    public let firstId: String?

    /// Last model ID in this page (use as `afterId` for next page).
    public let lastId: String?
}

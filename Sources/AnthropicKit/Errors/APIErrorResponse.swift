import Foundation

/// The error body returned by the Anthropic API.
///
/// When the API returns an HTTP error status code, the response body
/// contains a JSON object with `type` and `error` fields. The `error`
/// field contains the error `type` and human-readable `message`.
public struct APIErrorResponse: Codable, Sendable, Hashable {
    /// The top-level error type (always "error").
    public let type: String

    /// The error details.
    public let error: ErrorDetail

    /// Detailed error information from the API.
    public struct ErrorDetail: Codable, Sendable, Hashable {
        /// The specific error type (e.g., "invalid_request_error").
        public let type: String

        /// A human-readable description of the error.
        public let message: String
    }
}

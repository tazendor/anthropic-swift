import Foundation

/// Typed error for all AnthropicKit operations.
///
/// Every error from the library is represented as a case of this enum,
/// making it possible to handle errors exhaustively with `switch`.
public enum AnthropicError: Error, Sendable {
    /// The API returned an HTTP error with a parsed error body.
    case apiError(statusCode: Int, response: APIErrorResponse)

    /// A network connectivity or transport-level error occurred.
    case networkError(underlying: any Error)

    /// The response body could not be decoded.
    case decodingError(underlying: any Error)

    /// The SSE stream delivered an error event.
    case streamError(APIErrorResponse)

    /// The request was invalid before it was sent.
    case invalidRequest(reason: String)
}

// MARK: - CustomStringConvertible

extension AnthropicError: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .apiError(statusCode, response):
            "API error \(statusCode): "
                + "\(response.error.type) — \(response.error.message)"
        case let .networkError(underlying):
            "Network error: \(underlying.localizedDescription)"
        case let .decodingError(underlying):
            "Decoding error: \(underlying.localizedDescription)"
        case let .streamError(response):
            "Stream error: "
                + "\(response.error.type) — \(response.error.message)"
        case let .invalidRequest(reason):
            "Invalid request: \(reason)"
        }
    }
}

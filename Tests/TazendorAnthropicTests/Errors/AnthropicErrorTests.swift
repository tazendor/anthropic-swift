import Foundation
@testable import TazendorAnthropic
import Testing

/// Tests for AnthropicError descriptions and behavior.
struct AnthropicErrorTests {
    @Test("API error description includes status code and message")
    func apiError_description() {
        let response = APIErrorResponse(
            type: "error",
            error: .init(
                type: "invalid_request_error",
                message: "max_tokens required",
            ),
        )
        let error = AnthropicError.apiError(
            statusCode: 400,
            response: response,
        )

        let description = error.description
        #expect(description.contains("400"))
        #expect(description.contains("invalid_request_error"))
        #expect(description.contains("max_tokens required"))
    }

    @Test("Invalid request error includes reason")
    func invalidRequest_description() {
        let error = AnthropicError.invalidRequest(
            reason: "messages array is empty",
        )
        #expect(error.description.contains("messages array is empty"))
    }

    @Test("Network error includes underlying description")
    func networkError_description() {
        let underlying = URLError(.notConnectedToInternet)
        let error = AnthropicError.networkError(underlying: underlying)
        #expect(error.description.contains("Network error"))
    }
}

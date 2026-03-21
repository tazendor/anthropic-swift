import Foundation

/// A URLProtocol subclass that intercepts HTTP requests for testing.
///
/// Register a request handler before making requests. The handler
/// receives the URLRequest and returns a (response, data) tuple
/// or throws an error to simulate a network failure.
///
/// Usage:
/// ```swift
/// MockURLProtocol.requestHandler = { request in
///     let response = HTTPURLResponse(
///         url: request.url!, statusCode: 200,
///         httpVersion: nil, headerFields: nil
///     )!
///     return (response, someData)
/// }
/// ```
final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    /// Handler called for every intercepted request.
    /// Set this before making requests in your test.
    nonisolated(unsafe) static var requestHandler:
        ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override static func canInit(with _: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(
        for request: URLRequest,
    ) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(
                self,
                didFailWithError: URLError(.unknown),
            )
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(
                self,
                didReceive: response,
                cacheStoragePolicy: .notAllowed,
            )
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

/// Creates a URLSession configured to use MockURLProtocol.
func makeMockSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

import Foundation
import TazendorAI

/// Default implementation of `AnthropicClient` using `URLSession`.
///
/// Handles HTTP request construction, response parsing, and error
/// mapping for all Anthropic API endpoints. Streaming is implemented
/// via `URLSession.bytes(for:)` and `AsyncThrowingStream`.
public struct URLSessionAnthropicClient: AnthropicClient {
    private let configuration: AnthropicConfiguration
    private let session: URLSession

    /// Creates a client with the given configuration.
    /// - Parameter configuration: API configuration including key and base URL.
    public init(configuration: AnthropicConfiguration) {
        self.configuration = configuration
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest =
            configuration.timeoutInterval
        session = URLSession(configuration: sessionConfig)
    }

    /// Internal initializer for testing with a custom URLSession.
    init(
        configuration: AnthropicConfiguration,
        session: URLSession,
    ) {
        self.configuration = configuration
        self.session = session
    }

    // MARK: - AnthropicClient

    public func sendMessage(
        _ request: MessageRequest,
    ) async throws(AnthropicError) -> MessageResponse {
        // Ensure stream is not set for non-streaming requests
        var request = request
        if request.stream == true {
            request = MessageRequest(
                model: request.model,
                maxTokens: request.maxTokens,
                messages: request.messages,
                system: request.system,
                temperature: request.temperature,
                topP: request.topP,
                topK: request.topK,
                stopSequences: request.stopSequences,
                stream: nil,
                tools: request.tools,
                toolChoice: request.toolChoice,
                thinking: request.thinking,
                metadata: request.metadata,
            )
        }

        let data = try await performRequest(
            method: .post,
            path: "/v1/messages",
            body: request,
        )
        return try decode(MessageResponse.self, from: data)
    }

    public func streamMessage(
        _ request: MessageRequest,
    ) async throws(AnthropicError) -> AsyncThrowingStream<StreamEvent, Error> {
        let streamRequest = MessageRequest(
            model: request.model,
            maxTokens: request.maxTokens,
            messages: request.messages,
            system: request.system,
            temperature: request.temperature,
            topP: request.topP,
            topK: request.topK,
            stopSequences: request.stopSequences,
            stream: true,
            tools: request.tools,
            toolChoice: request.toolChoice,
            thinking: request.thinking,
            metadata: request.metadata,
        )

        let urlRequest: URLRequest
        do {
            urlRequest = try buildRequest(
                method: .post,
                path: "/v1/messages",
                body: streamRequest,
                queryItems: nil,
            )
        } catch {
            throw AnthropicError.invalidRequest(
                reason: "Failed to build request: \(error)",
            )
        }

        let (bytes, httpResponse) = try await performStreamRequest(
            urlRequest,
        )

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            throw await mapStreamError(
                bytes: bytes,
                statusCode: httpResponse.statusCode,
            )
        }

        return SSEParser.parse(lines: bytes.lines)
    }

    public func listModels(
        _ request: ModelListRequest,
    ) async throws(AnthropicError) -> ModelListResponse {
        var queryItems: [URLQueryItem] = []
        if let afterId = request.afterId {
            queryItems.append(URLQueryItem(name: "after_id", value: afterId))
        }
        if let beforeId = request.beforeId {
            queryItems.append(
                URLQueryItem(name: "before_id", value: beforeId),
            )
        }
        if let limit = request.limit {
            queryItems.append(
                URLQueryItem(name: "limit", value: String(limit)),
            )
        }

        let data = try await performRequest(
            method: .get,
            path: "/v1/models",
            queryItems: queryItems.isEmpty ? nil : queryItems,
        )
        return try decode(ModelListResponse.self, from: data)
    }

    public func retrieveModel(
        id: String,
    ) async throws(AnthropicError) -> ModelInfo {
        let data = try await performRequest(
            method: .get,
            path: "/v1/models/\(id)",
        )
        return try decode(ModelInfo.self, from: data)
    }

    // MARK: - Private

    private func performStreamRequest(
        _ urlRequest: URLRequest,
    ) async throws(AnthropicError) -> (URLSession.AsyncBytes, HTTPURLResponse) {
        let bytes: URLSession.AsyncBytes
        let response: URLResponse
        do {
            (bytes, response) = try await session.bytes(for: urlRequest)
        } catch {
            throw AnthropicError.networkError(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AnthropicError.networkError(
                underlying: URLError(.badServerResponse),
            )
        }

        return (bytes, httpResponse)
    }

    private func mapStreamError(
        bytes: URLSession.AsyncBytes,
        statusCode: Int,
    ) async -> AnthropicError {
        var errorData = Data()
        do {
            for try await byte in bytes {
                errorData.append(byte)
            }
        } catch {
            // Ignore collection errors; use what we have
        }
        let errorResponse = try? JSONCoders.decoder.decode(
            APIErrorResponse.self,
            from: errorData,
        )
        let fallback = APIErrorResponse(
            type: "error",
            error: .init(
                type: "unknown",
                message: "HTTP \(statusCode)",
            ),
        )
        return .apiError(
            statusCode: statusCode,
            response: errorResponse ?? fallback,
        )
    }

    private func performRequest(
        method: HTTPMethod,
        path: String,
        body: (some Encodable)? = nil as EmptyBody?,
        queryItems: [URLQueryItem]? = nil,
    ) async throws(AnthropicError) -> Data {
        let urlRequest: URLRequest
        do {
            urlRequest = try buildRequest(
                method: method,
                path: path,
                body: body,
                queryItems: queryItems,
            )
        } catch {
            throw AnthropicError.invalidRequest(
                reason: "Failed to build request: \(error)",
            )
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw AnthropicError.networkError(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AnthropicError.networkError(
                underlying: URLError(.badServerResponse),
            )
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            let errorResponse = try? JSONCoders.decoder.decode(
                APIErrorResponse.self,
                from: data,
            )
            let fallback = APIErrorResponse(
                type: "error",
                error: .init(
                    type: "unknown",
                    message: "HTTP \(httpResponse.statusCode)",
                ),
            )
            throw AnthropicError.apiError(
                statusCode: httpResponse.statusCode,
                response: errorResponse ?? fallback,
            )
        }

        return data
    }

    private func buildRequest(
        method: HTTPMethod,
        path: String,
        body: (some Encodable)?,
        queryItems: [URLQueryItem]?,
    ) throws -> URLRequest {
        var components = URLComponents(
            url: configuration.baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: true,
        )
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue(
            configuration.apiKey,
            forHTTPHeaderField: "x-api-key",
        )
        request.setValue(
            configuration.apiVersion,
            forHTTPHeaderField: "anthropic-version",
        )
        request.setValue(
            "application/json",
            forHTTPHeaderField: "content-type",
        )

        if let body {
            request.httpBody = try JSONCoders.encoder.encode(body)
        }

        return request
    }

    private func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data,
    ) throws(AnthropicError) -> T {
        do {
            return try JSONCoders.decoder.decode(type, from: data)
        } catch {
            throw AnthropicError.decodingError(underlying: error)
        }
    }
}

/// Empty body type for requests with no body (GET requests).
private struct EmptyBody: Encodable {}

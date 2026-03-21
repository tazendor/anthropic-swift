@testable import AnthropicKit
import Foundation
import Testing

/// Tests for URLSessionAnthropicClient HTTP behavior.
@Suite(.serialized)
struct URLSessionAnthropicClientTests {
    private let testConfig = AnthropicConfiguration(
        apiKey: "test-api-key",
        baseURL: URL(string: "https://api.anthropic.com")!,
    )

    private func makeClient() -> URLSessionAnthropicClient {
        URLSessionAnthropicClient(
            configuration: testConfig,
            session: makeMockSession(),
        )
    }

    private func loadFixture(_ name: String) throws -> Data {
        let url = Bundle.module.url(
            forResource: name,
            withExtension: "json",
            subdirectory: "Fixtures",
        )!
        return try Data(contentsOf: url)
    }

    // MARK: - sendMessage

    @Test("sendMessage returns decoded response on success")
    func sendMessage_whenSuccess_returnsResponse() async throws {
        let fixtureData = try loadFixture("message_response")
        MockURLProtocol.requestHandler = { request in
            #expect(request.httpMethod == "POST")
            #expect(request.url?.path == "/v1/messages")
            #expect(
                request.value(forHTTPHeaderField: "x-api-key")
                    == "test-api-key",
            )
            #expect(
                request.value(forHTTPHeaderField: "anthropic-version")
                    == "2023-06-01",
            )
            #expect(
                request.value(forHTTPHeaderField: "content-type")
                    == "application/json",
            )

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil,
            )!
            return (response, fixtureData)
        }

        let client = makeClient()
        let request = MessageRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [InputMessage(role: .user, text: "Hello")],
        )
        let response = try await client.sendMessage(request)

        #expect(response.id == "msg_01XFDUDYJgAACzvnptvVoYEL")
        #expect(response.stopReason == .endTurn)
    }

    @Test("sendMessage throws apiError on HTTP 400")
    func sendMessage_whenHTTP400_throwsApiError() async {
        let errorJSON = """
        {
            "type": "error",
            "error": {
                "type": "invalid_request_error",
                "message": "max_tokens is required"
            }
        }
        """
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: nil,
            )!
            return (response, Data(errorJSON.utf8))
        }

        let client = makeClient()
        let request = MessageRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 0,
            messages: [InputMessage(role: .user, text: "Hello")],
        )

        do {
            _ = try await client.sendMessage(request)
            Issue.record("Expected AnthropicError to be thrown")
        } catch {
            guard case let .apiError(statusCode, response) = error else {
                Issue.record("Expected apiError, got \(error)")
                return
            }
            #expect(statusCode == 400)
            #expect(response.error.type == "invalid_request_error")
        }
    }

    @Test("sendMessage throws apiError on HTTP 401")
    func sendMessage_whenHTTP401_throwsApiError() async {
        let errorJSON = """
        {
            "type": "error",
            "error": {
                "type": "authentication_error",
                "message": "invalid x-api-key"
            }
        }
        """
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil,
            )!
            return (response, Data(errorJSON.utf8))
        }

        let client = makeClient()
        let request = MessageRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [InputMessage(role: .user, text: "Hello")],
        )

        do {
            _ = try await client.sendMessage(request)
            Issue.record("Expected AnthropicError to be thrown")
        } catch {
            guard case let .apiError(statusCode, _) = error else {
                Issue.record("Expected apiError, got \(error)")
                return
            }
            #expect(statusCode == 401)
        }
    }

    @Test("sendMessage throws networkError on connection failure")
    func sendMessage_whenNetworkFailure_throwsNetworkError() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let client = makeClient()
        let request = MessageRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [InputMessage(role: .user, text: "Hello")],
        )

        do {
            _ = try await client.sendMessage(request)
            Issue.record("Expected AnthropicError to be thrown")
        } catch {
            guard case .networkError = error else {
                Issue.record("Expected networkError, got \(error)")
                return
            }
        }
    }

    @Test("sendMessage throws decodingError on malformed JSON")
    func sendMessage_whenMalformedJSON_throwsDecodingError() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil,
            )!
            return (response, Data("not json".utf8))
        }

        let client = makeClient()
        let request = MessageRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [InputMessage(role: .user, text: "Hello")],
        )

        do {
            _ = try await client.sendMessage(request)
            Issue.record("Expected AnthropicError to be thrown")
        } catch {
            guard case .decodingError = error else {
                Issue.record("Expected decodingError, got \(error)")
                return
            }
        }
    }

    // MARK: - listModels

    @Test("listModels returns decoded response on success")
    func listModels_whenSuccess_returnsResponse() async throws {
        let fixtureData = try loadFixture("model_list")
        MockURLProtocol.requestHandler = { request in
            #expect(request.httpMethod == "GET")
            #expect(request.url?.path == "/v1/models")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil,
            )!
            return (response, fixtureData)
        }

        let client = makeClient()
        let response = try await client.listModels(ModelListRequest())

        #expect(response.data.count == 1)
        #expect(response.data[0].id == "claude-sonnet-4-6")
        #expect(response.hasMore == false)
    }

    @Test("listModels includes pagination query parameters")
    func listModels_withPagination_sendsQueryParams() async throws {
        let fixtureData = try loadFixture("model_list")
        MockURLProtocol.requestHandler = { request in
            let components = URLComponents(
                url: request.url!,
                resolvingAgainstBaseURL: false,
            )
            let queryItems = components?.queryItems ?? []
            let params = Dictionary(
                uniqueKeysWithValues: queryItems.map {
                    ($0.name, $0.value ?? "")
                },
            )
            #expect(params["after_id"] == "claude-opus-4-6")
            #expect(params["limit"] == "5")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil,
            )!
            return (response, fixtureData)
        }

        let client = makeClient()
        _ = try await client.listModels(
            ModelListRequest(afterId: "claude-opus-4-6", limit: 5),
        )
    }

    // MARK: - retrieveModel

    @Test("retrieveModel returns decoded model info")
    func retrieveModel_whenSuccess_returnsModelInfo() async throws {
        let modelJSON = """
        {
            "id": "claude-sonnet-4-6",
            "type": "model",
            "display_name": "Claude Sonnet 4.6",
            "created_at": "2026-02-01T00:00:00Z",
            "max_input_tokens": 200000,
            "max_tokens": 8192
        }
        """
        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.path == "/v1/models/claude-sonnet-4-6")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil,
            )!
            return (response, Data(modelJSON.utf8))
        }

        let client = makeClient()
        let model = try await client.retrieveModel(id: "claude-sonnet-4-6")

        #expect(model.id == "claude-sonnet-4-6")
        #expect(model.displayName == "Claude Sonnet 4.6")
    }
}

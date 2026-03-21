/// Primary interface for interacting with the Anthropic Claude API.
///
/// All methods use structured concurrency and throw typed errors.
/// Use `URLSessionAnthropicClient` as the default implementation,
/// or provide your own conformance for testing.
public protocol AnthropicClient: Sendable {
    /// Sends a message request and returns the complete response.
    /// - Parameter request: The message request parameters.
    /// - Returns: The model's complete response.
    func sendMessage(
        _ request: MessageRequest,
    ) async throws(AnthropicError) -> MessageResponse

    /// Sends a message request with streaming, returning events as they arrive.
    /// - Parameter request: The message request parameters.
    /// - Returns: An async stream of server-sent events.
    func streamMessage(
        _ request: MessageRequest,
    ) async throws(AnthropicError) -> AsyncThrowingStream<StreamEvent, Error>

    /// Lists available models with optional pagination.
    /// - Parameter request: Pagination parameters.
    /// - Returns: A page of model information.
    func listModels(
        _ request: ModelListRequest,
    ) async throws(AnthropicError) -> ModelListResponse

    /// Retrieves information about a specific model.
    /// - Parameter id: The model identifier.
    /// - Returns: The model's information.
    func retrieveModel(
        id: String,
    ) async throws(AnthropicError) -> ModelInfo
}

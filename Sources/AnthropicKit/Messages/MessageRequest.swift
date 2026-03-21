import Foundation

/// A request to the Messages API.
///
/// At minimum, specify a `model`, `maxTokens`, and at least one message.
/// All other parameters are optional and control model behavior.
public struct MessageRequest: Codable, Sendable {
    /// The model identifier (e.g., "claude-sonnet-4-6").
    public let model: String

    /// Maximum tokens to generate in the response.
    public let maxTokens: Int

    /// The conversation messages.
    public let messages: [InputMessage]

    /// System prompt providing context or instructions.
    public let system: SystemPrompt?

    /// Sampling temperature (0.0–1.0).
    public let temperature: Double?

    /// Nucleus sampling probability cutoff.
    public let topP: Double?

    /// Top-K sampling parameter.
    public let topK: Int?

    /// Custom stop sequences.
    public let stopSequences: [String]?

    /// Whether to stream the response.
    public let stream: Bool?

    /// Tool definitions available to the model.
    public let tools: [ToolDefinition]?

    /// How the model should choose tools.
    public let toolChoice: ToolChoice?

    /// Extended thinking configuration.
    public let thinking: ThinkingConfig?

    /// Request metadata.
    public let metadata: Metadata?

    public init(
        model: String,
        maxTokens: Int,
        messages: [InputMessage],
        system: SystemPrompt? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        topK: Int? = nil,
        stopSequences: [String]? = nil,
        stream: Bool? = nil,
        tools: [ToolDefinition]? = nil,
        toolChoice: ToolChoice? = nil,
        thinking: ThinkingConfig? = nil,
        metadata: Metadata? = nil,
    ) {
        self.model = model
        self.maxTokens = maxTokens
        self.messages = messages
        self.system = system
        self.temperature = temperature
        self.topP = topP
        self.topK = topK
        self.stopSequences = stopSequences
        self.stream = stream
        self.tools = tools
        self.toolChoice = toolChoice
        self.thinking = thinking
        self.metadata = metadata
    }
}

/// System prompt content, either as a plain string or structured blocks.
public enum SystemPrompt: Sendable, Hashable {
    case text(String)
    case blocks([SystemBlock])
}

/// A block within a structured system prompt.
public struct SystemBlock: Codable, Sendable, Hashable {
    /// Block type (always "text").
    public let type: String

    /// The text content.
    public let text: String

    /// Optional cache control.
    public let cacheControl: CacheControl?

    public init(text: String, cacheControl: CacheControl? = nil) {
        type = "text"
        self.text = text
        self.cacheControl = cacheControl
    }
}

// MARK: - SystemPrompt Codable

extension SystemPrompt: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            self = .text(text)
        } else {
            let blocks = try container.decode([SystemBlock].self)
            self = .blocks(blocks)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .text(text):
            try container.encode(text)
        case let .blocks(blocks):
            try container.encode(blocks)
        }
    }
}

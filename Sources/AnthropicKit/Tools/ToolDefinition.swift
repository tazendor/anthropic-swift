/// A tool definition provided to the model.
///
/// Tools allow the model to request actions. Each tool has a name,
/// description, and a JSON Schema defining its expected input.
public struct ToolDefinition: Codable, Sendable, Hashable {
    /// The tool name (must match `[a-zA-Z0-9_-]+`).
    public let name: String

    /// A description of what the tool does. The model uses this
    /// to decide when and how to use the tool.
    public let description: String?

    /// JSON Schema for the tool's input parameters.
    public let inputSchema: ToolInputSchema

    public init(
        name: String,
        description: String? = nil,
        inputSchema: ToolInputSchema,
    ) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
    }
}

/// A tool use content block in a message response.
///
/// Indicates the model wants to call a tool. The `input` field
/// contains the tool's arguments as arbitrary JSON.
public struct ToolUseBlock: Codable, Sendable, Hashable {
    /// Unique identifier for this tool use, used to match results.
    public let id: String

    /// The name of the tool to call.
    public let name: String

    /// The tool's input arguments as arbitrary JSON.
    public let input: JSONValue

    public init(id: String, name: String, input: JSONValue) {
        self.id = id
        self.name = name
        self.input = input
    }
}

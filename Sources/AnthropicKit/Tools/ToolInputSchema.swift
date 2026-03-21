/// JSON Schema definition for a tool's input parameters.
///
/// Follows the JSON Schema specification. The `type` is typically
/// "object" with `properties` defining each parameter.
public struct ToolInputSchema: Codable, Sendable, Hashable {
    /// The schema type (typically "object").
    public let type: String

    /// Property definitions keyed by parameter name.
    public let properties: [String: JSONValue]?

    /// Required property names.
    public let required: [String]?

    public init(
        type: String = "object",
        properties: [String: JSONValue]? = nil,
        required: [String]? = nil,
    ) {
        self.type = type
        self.properties = properties
        self.required = required
    }
}

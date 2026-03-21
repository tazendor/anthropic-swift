import Foundation

/// Preconfigured JSON encoder for Anthropic API requests.
enum JSONCoders {
    /// Encoder configured for Anthropic API snake_case conventions.
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    /// Decoder configured for Anthropic API snake_case conventions.
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}

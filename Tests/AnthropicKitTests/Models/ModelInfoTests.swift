@testable import AnthropicKit
import Foundation
import Testing

/// Tests for model info and capabilities decoding.
struct ModelInfoTests {
    @Test("ModelInfo with full capabilities decodes correctly")
    func modelInfo_withCapabilities_decodesCorrectly() throws {
        let json = """
        {
            "id": "claude-opus-4-6",
            "type": "model",
            "display_name": "Claude Opus 4.6",
            "created_at": "2026-02-01T00:00:00Z",
            "max_input_tokens": 200000,
            "max_tokens": 32768,
            "capabilities": {
                "batch": {"supported": true},
                "citations": {"supported": true},
                "code_execution": {"supported": true},
                "image_input": {"supported": true},
                "pdf_input": {"supported": true},
                "structured_outputs": {"supported": true},
                "thinking": {
                    "supported": true,
                    "types": {
                        "enabled": {"supported": true},
                        "adaptive": {"supported": true}
                    }
                },
                "effort": {
                    "supported": true,
                    "low": {"supported": true},
                    "medium": {"supported": true},
                    "high": {"supported": true},
                    "max": {"supported": true}
                }
            }
        }
        """

        let data = Data(json.utf8)
        let model = try JSONCoders.decoder.decode(
            ModelInfo.self,
            from: data,
        )

        #expect(model.id == "claude-opus-4-6")
        #expect(model.maxTokens == 32768)
        #expect(model.capabilities?.thinking?.supported == true)
        #expect(
            model.capabilities?.thinking?.types?.adaptive?.supported == true,
        )
        #expect(model.capabilities?.effort?.supported == true)
        #expect(model.capabilities?.effort?.max?.supported == true)
    }

    @Test("ModelInfo without capabilities decodes correctly")
    func modelInfo_withoutCapabilities_decodesCorrectly() throws {
        let json = """
        {
            "id": "claude-3-haiku-20240307",
            "type": "model",
            "display_name": "Claude 3 Haiku",
            "created_at": "2024-03-07T00:00:00Z",
            "max_input_tokens": 200000,
            "max_tokens": 4096
        }
        """

        let data = Data(json.utf8)
        let model = try JSONCoders.decoder.decode(
            ModelInfo.self,
            from: data,
        )

        #expect(model.id == "claude-3-haiku-20240307")
        #expect(model.capabilities == nil)
    }
}

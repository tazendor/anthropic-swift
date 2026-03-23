# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] — 2026-03-23

### Breaking

- **Module renamed** from `AnthropicKit` to `TazendorAnthropic`. Update your
  imports: `import TazendorAnthropic`.
- **Package URL changed** to `https://github.com/tazendor/anthropic-swift.git`.

### Added

- `TazendorAI` dependency — shared provider-agnostic types from the
  [ai-swift](https://github.com/tazendor/ai-swift) foundation library.
- `AnthropicAIProvider` — adapter conforming to `AIClient` protocol for
  provider-agnostic usage.
- `AIOptionKey` extensions for Anthropic-specific parameters:
  `.anthropicTopP`, `.anthropicTopK`, `.anthropicThinkingBudget`,
  `.anthropicUserId`.
- `AICapability.thinking` extension for extended thinking capability.
- 16 new tests for the `AnthropicAIProvider` mapping layer (60 total).

### Removed

- Duplicated types now provided by TazendorAI: `JSONValue`, `JSONCoders`,
  `HTTPMethod`, `ToolDefinition`, `ToolInputSchema`, `ToolChoice`.

### Changed

- `SSEParser` now delegates raw line parsing to TazendorAI's `SSELineParser`,
  keeping only the Anthropic-specific JSON deserialization layer.

## [0.1.0] — 2026-03-21

### Added

- `AnthropicClient` protocol with four operations: `sendMessage`,
  `streamMessage`, `listModels`, `retrieveModel`
- `URLSessionAnthropicClient` default implementation using URLSession
- Messages API: `MessageRequest`, `MessageResponse`, full content block
  types (text, tool_use, thinking, redacted_thinking)
- Streaming via `AsyncThrowingStream<StreamEvent, Error>` with SSE parsing
- Tool use: `ToolDefinition`, `ToolChoice`, `ToolInputSchema`, `JSONValue`
- Extended thinking: `ThinkingConfig`, thinking/signature deltas
- Models API: `ModelInfo`, `ModelCapabilities`, pagination support
- Typed errors via `AnthropicError` enum
- 44 unit tests with JSON fixture validation

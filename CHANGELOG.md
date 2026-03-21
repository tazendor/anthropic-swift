# Changelog

All notable changes to AnthropicKit are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

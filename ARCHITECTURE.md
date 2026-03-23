# Architecture — TazendorAnthropic

## Overview

TazendorAnthropic is a Swift Package providing typed access to the Anthropic
Claude API. It wraps three endpoints: Messages (send + stream), and Models
(list + retrieve).

As of 0.2.0, it depends on [TazendorAI](https://github.com/tazendor/ai-swift)
for shared, provider-agnostic types and exposes an `AnthropicAIProvider` that
conforms to the `AIClient` protocol.

## Decisions

### 1. ContentBlock as enum with associated values

**Context:** The API returns content blocks with a `type` discriminator. We
need to represent text, tool_use, thinking, and redacted_thinking blocks.

**Decision:** Use a Swift enum with associated values and custom Codable that
dispatches on the `type` field.

**Rationale:** Enums are value types, naturally Sendable, and exhaustive
`switch` forces callers to handle all cases. A class hierarchy would add
reference semantics and lose exhaustiveness.

**Consequences:** Adding a new block type requires updating the enum and its
Codable implementation. This is intentional — new API features should be
explicit additions.

### 2. AsyncThrowingStream for streaming

**Context:** The streaming API uses Server-Sent Events. We need an async
interface for consumers.

**Decision:** Return `AsyncThrowingStream<StreamEvent, Error>`.

**Rationale:** This is the standard library type for bridging push-based
sources. It works with `for await`, handles cancellation via `onTermination`,
and is well-understood. A custom `AsyncSequence` would add complexity without
benefit.

### 3. TazendorAI dependency for shared types

**Context:** Multiple provider libraries (Anthropic, OpenAI, etc.) need the
same tool types, JSON value type, SSE parsing, and client protocol. Duplicating
these across libraries causes divergence and maintenance burden.

**Decision:** Depend on TazendorAI (`tazendor/ai-swift`) for `JSONValue`,
`JSONCoders`, `HTTPMethod`, `ToolDefinition`, `ToolInputSchema`, `ToolChoice`,
`SSELineParser`, and the `AIClient` protocol.

**Rationale:** TazendorAI was extracted specifically to hold these types. The
implementations were identical across the two libraries — no adaptation needed.
SSEParser now delegates raw line parsing to `SSELineParser` and keeps only the
Anthropic-specific JSON deserialization layer.

**Consequences:** Consumers must add `import TazendorAI` alongside
`import TazendorAnthropic` if they use shared types directly. We chose not to
use `@_exported import` since it is an underscored API and keeping imports
explicit makes the dependency graph visible.

### 4. AnthropicAIProvider adapter pattern

**Context:** Apps want to use multiple AI providers interchangeably. The
`AIClient` protocol from TazendorAI defines the contract.

**Decision:** `AnthropicAIProvider` is a `struct` that wraps any
`AnthropicClient` conformance and maps between the two type systems.

**Rationale:** The adapter sits on top of the existing typed client rather
than replacing it. Users who need Anthropic-specific features (thinking blocks,
cache control, redacted thinking) use `AnthropicClient` directly. Users who
want provider-agnostic code use `AnthropicAIProvider` via `AIClient`.

**Mapping details:**
- `AIRequest` → `MessageRequest`: direct field mapping + `AIOptionKey`
  extraction for topP, topK, thinking budget, userId
- `MessageResponse` → `AIResponse`: text and tool_use blocks are mapped;
  thinking and redacted_thinking blocks are dropped (not representable in the
  agnostic model)
- `StreamEvent` → `AIStreamEvent`: text deltas and tool call events are
  mapped; the provider tracks tool IDs across events and accumulates the full
  response for the `.done` event
- `AnthropicError` → `AIError`: direct case mapping; `streamError` maps to
  `providerError`

### 5. MockURLProtocol for testing

**Context:** We need to test HTTP behavior without real network calls.

**Decision:** Use a `URLProtocol` subclass that intercepts requests and returns
canned responses. Inject via `URLSessionConfiguration.protocolClasses`.

**Rationale:** Tests the real `URLSession` code path without a protocol
abstraction layer. Simpler than wrapping URLSession in a protocol + mock.
Tests must be serialized since MockURLProtocol uses a static handler.

### 6. Single AnthropicError enum

**Context:** Errors can come from HTTP status codes, network failures, JSON
decoding, or SSE stream events.

**Decision:** One `AnthropicError` enum with cases for each origin.

**Rationale:** The API has a consistent error model. A single typed error keeps
the surface small. The `apiError` case carries status code + parsed body.

### 7. DeltaUsage separate from Usage

**Context:** The `message_delta` SSE event contains a `usage` object with only
`output_tokens`, while the full response `usage` has both input and output.

**Decision:** Separate `DeltaUsage` struct with just `outputTokens`.

**Rationale:** Avoids making `inputTokens` optional in the primary `Usage`
type, which would weaken the type safety of non-streaming responses.

### 8. Certificate pinning deferred

**Context:** Certificate pinning for AI provider API calls is a security best
practice.

**Decision:** Deferred to a hardening phase. Track as a GitHub issue when the
repo is published.

**Rationale:** Pinning doesn't affect API design. Getting it wrong causes
mysterious connection failures on cert rotation. Better to implement as a
focused security task with proper testing after core functionality works.

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| [TazendorAI](https://github.com/tazendor/ai-swift) | 0.1.0+ | Shared provider-agnostic types, `AIClient` protocol, SSE line parsing |

## Known Limitations

- No retry logic — rate limiting is surfaced via `AnthropicError.apiError`
  with status 429; consumers decide retry policy
- No prompt caching helpers beyond `CacheControl` type passthrough
- Certificate pinning not yet implemented (hardening phase)
- Thinking blocks are not mapped to `AIContentPart` — access them via
  `AnthropicClient` directly

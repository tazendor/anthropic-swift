# Architecture — AnthropicKit

## Overview

AnthropicKit is a Swift Package providing typed access to the Anthropic Claude
API. It wraps three endpoints: Messages (send + stream), and Models (list +
retrieve).

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

### 3. JSONValue recursive enum for arbitrary JSON

**Context:** Tool use inputs are arbitrary JSON. Swift has no native "any JSON"
type.

**Decision:** A recursive enum with cases for string, number, bool, object,
array, and null. Conforms to Codable, Sendable, Hashable, and all
ExpressibleBy literal protocols.

**Rationale:** Zero-dependency, type-safe, and avoids `Any` or type erasure.
Under 100 lines of code.

### 4. MockURLProtocol for testing

**Context:** We need to test HTTP behavior without real network calls.

**Decision:** Use a `URLProtocol` subclass that intercepts requests and returns
canned responses. Inject via `URLSessionConfiguration.protocolClasses`.

**Rationale:** Tests the real `URLSession` code path without a protocol
abstraction layer. Simpler than wrapping URLSession in a protocol + mock.
Tests must be serialized since MockURLProtocol uses a static handler.

### 5. Single AnthropicError enum

**Context:** Errors can come from HTTP status codes, network failures, JSON
decoding, or SSE stream events.

**Decision:** One `AnthropicError` enum with cases for each origin.

**Rationale:** The API has a consistent error model. A single typed error keeps
the surface small. The `apiError` case carries status code + parsed body.

### 6. DeltaUsage separate from Usage

**Context:** The `message_delta` SSE event contains a `usage` object with only
`output_tokens`, while the full response `usage` has both input and output.

**Decision:** Separate `DeltaUsage` struct with just `outputTokens`.

**Rationale:** Avoids making `inputTokens` optional in the primary `Usage`
type, which would weaken the type safety of non-streaming responses.

### 7. Certificate pinning deferred

**Context:** CODEGUARD.md requires certificate pinning for AI provider API
calls.

**Decision:** Deferred to a hardening phase. Document as a tracked GitHub issue
when the repo is published.

**Rationale:** Pinning doesn't affect API design. Getting it wrong causes
mysterious connection failures on cert rotation. Better to implement as a
focused security task with proper testing after core functionality works.

## Dependencies

None. This is a zero-dependency package per GOVERNANCE.md policy.

## Known Limitations

- No retry logic — rate limiting is surfaced via `AnthropicError.apiError`
  with status 429; consumers decide retry policy
- No prompt caching helpers beyond `CacheControl` type passthrough
- Certificate pinning not yet implemented (hardening phase)

# CLAUDE.md — AnthropicKit
## Claude Code Session Context

---

> **MANDATORY:** Read `~/Develop/Swift/GOVERNANCE.md` before writing any code.

---

## What This Project Is

AnthropicKit is a zero-dependency Swift Package wrapping the Anthropic Claude
API. It provides typed, protocol-backed access to the Messages API (send and
stream), tool use, extended thinking, and model listing. It is Phase 1 of the
workspace roadmap, consumed by AIProviderKit (Phase 2) and NotifyAI (Phase 3).

## Current Phase

**v0.1.0 — Complete**

All phases (1A–1F) done. 44 tests, 73% coverage.

Blocked on: nothing

## Architecture Constraints

- Zero external dependencies — everything uses Foundation/URLSession
- iOS 18+ / macOS 15+ platform targets
- Swift 6.1+ with strict concurrency
- All types are Codable and Sendable
- AnthropicClient is a protocol for testability
- URLSession tested via MockURLProtocol (no protocol wrapping URLSession)
- API key is never stored or logged by this library

## Key Decisions Made

- ContentBlock as enum with associated values (not class hierarchy) — value type, Sendable, exhaustive switch
- AsyncThrowingStream<StreamEvent, Error> for streaming — standard library type, no custom AsyncSequence
- JSONValue recursive enum for arbitrary JSON in tool inputs — avoids Any and type erasure
- Single AnthropicError enum — consistent error surface across all operations
- DeltaUsage separate from Usage — message_delta events only have output_tokens
- Certificate pinning deferred to hardening phase — tracked requirement, not blocking core API

## Known Issues

- None

## Do Not Touch

- ~/Develop/Swift/GOVERNANCE.md (workspace-level)

## Session Goal

Package is complete. Next work: publish to GitHub, or proceed to Phase 2 (AIProviderKit) on instruction.

---

## How To Start Working

```bash
cd ~/Develop/Swift/Libraries/AnthropicKit
swift build          # confirm it builds before making changes
swift test           # confirm tests pass before making changes
```

Then complete Phase 1F per the plan at ~/.claude/plans/soft-floating-sketch.md.

Stop after Phase 1F and show a summary of what was built.
Do not proceed to Phase 2 (AIProviderKit) without explicit instruction.

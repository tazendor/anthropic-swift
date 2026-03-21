# CLAUDE.md — AnthropicKit
## Claude Code Session Context

---

> **MANDATORY:** Read `~/Develop/Swift/GOVERNANCE.md` and
> `~/Develop/Swift/CODEGUARD.md` before writing any code.
> Confirm you have read both at the start of your response.

---

## What This Project Is

AnthropicKit is a zero-dependency Swift Package wrapping the Anthropic Claude
API. It provides typed, protocol-backed access to the Messages API (send and
stream), tool use, extended thinking, and model listing. It is Phase 1 of the
workspace roadmap, consumed by AIProviderKit (Phase 2) and NotifyAI (Phase 3).

## Current Phase

**Phase 1F — Polish + CI**

Active work: Doc comments, README, ARCHITECTURE.md, CI workflow, linting, git init

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
- ~/Develop/Swift/CODEGUARD.md (workspace-level)

## Session Goal

Complete Phase 1F: polish, documentation, CI, and publish readiness.

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

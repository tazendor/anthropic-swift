# TazendorAnthropic

A Swift Package for the Anthropic Claude API, part of the
[Tazendor](https://github.com/tazendor) AI ecosystem.

Provides both a typed Anthropic-specific client (`AnthropicClient`) and a
provider-agnostic adapter (`AnthropicAIProvider` via `AIClient` from
[TazendorAI](https://github.com/tazendor/ai-swift)).

## Requirements

- Swift 6.1+ / Xcode 26+
- iOS 18+ or macOS 15+

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/tazendor/anthropic-swift.git", from: "0.2.0")
]
```

Then add `"TazendorAnthropic"` to your target's dependencies.

## Quick Start — Provider-Agnostic (AIClient)

```swift
import TazendorAI
import TazendorAnthropic

let provider = AnthropicAIProvider(
    configuration: AnthropicConfiguration(apiKey: "your-api-key")
)

let response = try await provider.sendMessage(
    AIRequest(
        model: "claude-sonnet-4-6",
        maxTokens: 1024,
        messages: [AIMessage(role: .user, text: "Hello, Claude!")]
    )
)
```

## Quick Start — Anthropic-Specific

```swift
import TazendorAnthropic

let client = URLSessionAnthropicClient(
    configuration: AnthropicConfiguration(apiKey: "your-api-key")
)

let response = try await client.sendMessage(MessageRequest(
    model: "claude-sonnet-4-6",
    maxTokens: 1024,
    messages: [InputMessage(role: .user, text: "Hello, Claude!")]
))

print(response.content) // [.text(TextBlock(text: "Hello! How can I help?"))]
```

## Streaming

```swift
let stream = try await client.streamMessage(MessageRequest(
    model: "claude-sonnet-4-6",
    maxTokens: 1024,
    messages: [InputMessage(role: .user, text: "Tell me a story")]
))

for try await event in stream {
    switch event {
    case .contentBlockDelta(_, let delta):
        if case .textDelta(let text) = delta {
            print(text, terminator: "")
        }
    case .messageStop:
        print() // newline at end
    default:
        break
    }
}
```

## Tool Use

```swift
let tool = ToolDefinition(
    name: "get_weather",
    description: "Get current weather for a location",
    inputSchema: ToolInputSchema(
        properties: [
            "location": .object(["type": .string("string")])
        ],
        required: ["location"]
    )
)

let response = try await client.sendMessage(MessageRequest(
    model: "claude-sonnet-4-6",
    maxTokens: 1024,
    messages: [InputMessage(role: .user, text: "Weather in NYC?")],
    tools: [tool]
))
```

## Extended Thinking

```swift
let response = try await client.sendMessage(MessageRequest(
    model: "claude-opus-4-6",
    maxTokens: 16000,
    messages: [InputMessage(role: .user, text: "Solve this step by step...")],
    thinking: .enabled(budgetTokens: 10000)
))
```

Or via the provider-agnostic interface:

```swift
let response = try await provider.sendMessage(
    AIRequest(
        model: "claude-opus-4-6",
        maxTokens: 16000,
        messages: [AIMessage(role: .user, text: "Solve this step by step...")],
        options: [.anthropicThinkingBudget: .number(10000)]
    )
)
```

## List Models

```swift
let models = try await client.listModels(ModelListRequest())
for model in models.data {
    print("\(model.id) — \(model.displayName)")
}
```

## Error Handling

All methods throw `AnthropicError` (typed client) or `AIError` (provider):

```swift
do {
    let response = try await client.sendMessage(request)
} catch {
    switch error {
    case .apiError(let status, let response):
        print("API error \(status): \(response.error.message)")
    case .networkError(let underlying):
        print("Network: \(underlying.localizedDescription)")
    case .decodingError(let underlying):
        print("Decode: \(underlying)")
    default:
        print(error)
    }
}
```

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for design decisions and rationale.

## License

MIT

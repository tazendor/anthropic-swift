/// A server-sent event from the streaming Messages API.
///
/// Events arrive in a defined sequence: `messageStart`, then a series
/// of content block events, then `messageDelta` and `messageStop`.
public enum StreamEvent: Sendable {
    /// The stream has started; contains the initial message shell.
    case messageStart(MessageResponse)

    /// A new content block has started at the given index.
    case contentBlockStart(index: Int, contentBlock: ContentBlock)

    /// A delta update for the content block at the given index.
    case contentBlockDelta(index: Int, delta: Delta)

    /// The content block at the given index is complete.
    case contentBlockStop(index: Int)

    /// Final message-level updates (stop reason, usage).
    case messageDelta(MessageDeltaPayload)

    /// The stream is complete.
    case messageStop

    /// A keep-alive ping.
    case ping

    /// An error event from the stream.
    case error(APIErrorResponse)
}

/// Payload for the `message_delta` streaming event.
public struct MessageDeltaPayload: Codable, Sendable, Hashable {
    /// The delta containing stop reason.
    public let delta: DeltaBody

    /// Updated usage statistics (only `outputTokens` in delta events).
    public let usage: DeltaUsage?

    /// Usage statistics specific to message_delta events.
    /// Unlike the full `Usage` type, only `outputTokens` is present.
    public struct DeltaUsage: Codable, Sendable, Hashable {
        /// Number of output tokens generated so far.
        public let outputTokens: Int
    }

    /// The body of a message delta.
    public struct DeltaBody: Codable, Sendable, Hashable {
        /// The reason generation stopped.
        public let stopReason: StopReason?

        /// The matched stop sequence, if any.
        public let stopSequence: String?
    }
}

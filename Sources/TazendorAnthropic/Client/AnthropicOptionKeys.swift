import TazendorAI

public extension AIOptionKey {
    /// Top-P (nucleus) sampling parameter.
    static let anthropicTopP = AIOptionKey(
        rawValue: "anthropic.topP",
    )

    /// Top-K sampling parameter.
    static let anthropicTopK = AIOptionKey(
        rawValue: "anthropic.topK",
    )

    /// Extended thinking token budget.
    ///
    /// Pass as `.number(Double(budgetTokens))`. Minimum 1,024.
    static let anthropicThinkingBudget = AIOptionKey(
        rawValue: "anthropic.thinkingBudget",
    )

    /// User ID for request metadata (abuse prevention).
    static let anthropicUserId = AIOptionKey(
        rawValue: "anthropic.userId",
    )
}

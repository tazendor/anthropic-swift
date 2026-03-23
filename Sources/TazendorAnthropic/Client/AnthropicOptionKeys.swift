import TazendorAI

extension AIOptionKey {
    /// Top-P (nucleus) sampling parameter.
    public static let anthropicTopP = AIOptionKey(
        rawValue: "anthropic.topP"
    )

    /// Top-K sampling parameter.
    public static let anthropicTopK = AIOptionKey(
        rawValue: "anthropic.topK"
    )

    /// Extended thinking token budget.
    ///
    /// Pass as `.number(Double(budgetTokens))`. Minimum 1,024.
    public static let anthropicThinkingBudget = AIOptionKey(
        rawValue: "anthropic.thinkingBudget"
    )

    /// User ID for request metadata (abuse prevention).
    public static let anthropicUserId = AIOptionKey(
        rawValue: "anthropic.userId"
    )
}

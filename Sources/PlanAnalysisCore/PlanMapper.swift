import Foundation

public enum PlanMapper {
    public static func claude(subscriptionType: String?, rateLimitTier: String?) -> Subscription? {
        let raw = [subscriptionType, rateLimitTier]
            .compactMap { $0?.lowercased() }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        guard !raw.isEmpty else { return nil }
        if raw.contains("20") || raw.contains("max20") || raw.contains("max_20") {
            return sub(.claude, "claude-max20", "Claude Max 20x", raw)
        }
        if raw.contains("5") && raw.contains("max") || raw.contains("max5") || raw.contains("max_5") {
            return sub(.claude, "claude-max5", "Claude Max 5x", raw)
        }
        if raw.contains("max") {
            return sub(.claude, "claude-max5", "Claude Max", raw)
        }
        if raw.contains("pro") {
            return sub(.claude, "claude-pro", "Claude Pro", raw)
        }
        if raw.contains("team") || raw.contains("enterprise") {
            return sub(.claude, "claude-pro", "Claude \(subscriptionType ?? rateLimitTier ?? "Team")", raw)
        }
        return nil
    }

    public static func chatgpt(planType: String?) -> Subscription? {
        let raw = (planType ?? "").lowercased()
        guard !raw.isEmpty else { return nil }
        if raw.contains("20") { return sub(.codex, "gpt-pro-20x", "ChatGPT Pro 20x", raw) }
        if raw.contains("5") && raw.contains("pro") { return sub(.codex, "gpt-pro-5x", "ChatGPT Pro 5x", raw) }
        if raw == "pro" || raw.contains("pro") { return sub(.codex, "gpt-pro-20x", "ChatGPT Pro", raw) }
        if raw.contains("plus") { return sub(.codex, "gpt-plus", "ChatGPT Plus", raw) }
        if raw.contains("free") { return nil }
        return nil
    }

    public static func cursor(membership: String?) -> Subscription? {
        let raw = (membership ?? "").lowercased()
        guard !raw.isEmpty else { return nil }
        if raw.contains("ultra") { return sub(.cursor, "cursor-ultra", "Cursor Ultra", raw) }
        if raw.contains("pro_plus") || raw.contains("proplus") || raw.contains("pro+") || raw.contains("pro plus") {
            return sub(.cursor, "cursor-proplus", "Cursor Pro+", raw)
        }
        if raw.contains("pro") { return sub(.cursor, "cursor-pro", "Cursor Pro", raw) }
        if raw.contains("free") || raw.contains("hobby") { return nil }
        return nil
    }

    private static func sub(_ provider: ProviderID, _ id: String, _ label: String, _ raw: String) -> Subscription {
        Subscription(provider: provider, planId: id, planLabel: label, email: nil, source: "", rawTier: raw)
    }
}

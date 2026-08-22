import Foundation

public enum TokenExtractor {
    public static func deltas(fromJSONLine line: String, provider: ProviderID) -> [TokenDelta] {
        guard let data = line.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [] }
        switch provider {
        case .claude:
            return claude(obj)
        case .codex:
            return codex(obj)
        }
    }

    private static func claude(_ obj: [String: Any]) -> [TokenDelta] {
        guard obj["type"] as? String == "assistant" else { return [] }
        guard let message = obj["message"] as? [String: Any],
              let usage = message["usage"] as? [String: Any]
        else { return [] }
        return [delta(at: date(obj["timestamp"]), usage: usage, preferLast: false)]
    }

    private static func codex(_ obj: [String: Any]) -> [TokenDelta] {
        guard obj["type"] as? String == "event_msg" else { return [] }
        guard let payload = obj["payload"] as? [String: Any],
              payload["type"] as? String == "token_count"
        else { return [] }
        let info = payload["info"] as? [String: Any] ?? [:]
        // last_token_usage is the increment; total_token_usage is cumulative.
        if let last = info["last_token_usage"] as? [String: Any] {
            return [delta(at: date(obj["timestamp"]), usage: last, preferLast: true)]
        }
        return []
    }

    private static func delta(at: Date, usage: [String: Any], preferLast: Bool) -> TokenDelta {
        _ = preferLast
        return TokenDelta(
            at: at,
            input: int(usage["input_tokens"]),
            output: int(usage["output_tokens"]) + int(usage["reasoning_output_tokens"]),
            cacheRead: int(usage["cache_read_input_tokens"]) + int(usage["cached_input_tokens"]),
            cacheCreate: int(usage["cache_creation_input_tokens"])
        )
    }

    private static func int(_ value: Any?) -> Int {
        switch value {
        case let n as Int: return n
        case let n as Int64: return Int(n)
        case let n as Double: return Int(n)
        case let n as NSNumber: return n.intValue
        default: return 0
        }
    }

    private static func date(_ value: Any?) -> Date {
        if let s = value as? String, let parsed = ISO8601DateParser.date(from: s) {
            return parsed
        }
        return Date()
    }
}

enum ISO8601DateParser {
    static func date(from string: String) -> Date? {
        let frac = ISO8601DateFormatter()
        frac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = frac.date(from: string) { return d }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: string)
    }
}

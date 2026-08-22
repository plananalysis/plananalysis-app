import Foundation

public enum Exporter {
    public static func jsonData(from snapshot: UsageSnapshot) throws -> Data {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        return try enc.encode(snapshot)
    }

    public static func csvString(from snapshot: UsageSnapshot) -> String {
        var rows = ["provider,plan_id,plan_label,plan_source,window,input_tokens,output_tokens,cache_read_tokens,equiv_usd,events,captured_at"]
        let stamp = ISO8601DateFormatter().string(from: snapshot.capturedAt)
        for p in snapshot.providers {
            for w in p.windows {
                rows.append(
                    [
                        p.provider.rawValue,
                        p.planId,
                        csv(p.planLabel),
                        p.planSource.rawValue,
                        w.kind.rawValue,
                        String(w.inputTokens),
                        String(w.outputTokens),
                        String(w.cacheReadTokens),
                        String(format: "%.4f", w.equivUsd),
                        String(w.eventCount),
                        stamp,
                    ].joined(separator: ",")
                )
            }
        }
        return rows.joined(separator: "\n") + "\n"
    }

    public static func ladderEntries(from snapshot: UsageSnapshot, displayName: String) -> [LadderEntry] {
        snapshot.providers.compactMap { p in
            guard p.canUpload else { return nil }
            let w = p.window(.month)
            return LadderEntry(
                planId: p.planId,
                provider: p.provider.rawValue,
                displayName: displayName,
                window: w.kind.rawValue,
                inputTokens: w.inputTokens,
                outputTokens: w.outputTokens,
                cacheReadTokens: w.cacheReadTokens,
                equivUsd: w.equivUsd,
                capturedAt: snapshot.capturedAt
            )
        }
    }

    private static func csv(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") {
            return "\"\(s.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return s
    }
}

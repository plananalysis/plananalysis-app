import Foundation

public enum UsageAggregator {
    public static func windows(from deltas: [TokenDelta], now: Date = Date()) -> [UsageWindow] {
        WindowKind.allCases.map { kind in
            let start = now.addingTimeInterval(-seconds(kind))
            var input = 0
            var output = 0
            var cache = 0
            var count = 0
            for d in deltas where d.at >= start {
                input += d.input
                output += d.output
                cache += d.cacheRead
                count += 1
            }
            return UsageWindow(
                kind: kind,
                inputTokens: input,
                outputTokens: output,
                cacheReadTokens: cache,
                eventCount: count
            )
        }
    }

    private static func seconds(_ kind: WindowKind) -> TimeInterval {
        switch kind {
        case .hours5: return 5 * 3600
        case .week: return 7 * 24 * 3600
        case .month: return 30 * 24 * 3600
        }
    }
}

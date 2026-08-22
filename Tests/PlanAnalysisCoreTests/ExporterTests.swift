import Foundation
import Testing
@testable import PlanAnalysisCore

@Suite
struct ExporterTests {
    @Test
    func csvHasHeaderAndRows() {
        let snap = UsageSnapshot(
            capturedAt: Date(timeIntervalSince1970: 1_777_000_000),
            providers: [
                ProviderSnapshot(
                    provider: .claude,
                    planId: "claude-pro",
                    windows: [
                        UsageWindow(kind: .hours5, inputTokens: 10, outputTokens: 2, cacheReadTokens: 1, eventCount: 1)
                    ],
                    lastEventAt: nil,
                    filesScanned: 1,
                    bytesRead: 8,
                    elapsedMs: 1
                )
            ],
            scanMs: 2
        )
        let csv = Exporter.csvString(from: snap)
        #expect(csv.contains("provider,plan_id,window"))
        #expect(csv.contains("claude,claude-pro,5h,10,2,1,1"))
    }

    @Test
    func ladderSkipsEmptyFiveHour() {
        let empty = ProviderSnapshot(
            provider: .codex,
            planId: "gpt-plus",
            windows: [UsageWindow(kind: .hours5, inputTokens: 0, outputTokens: 0, cacheReadTokens: 0, eventCount: 0)],
            lastEventAt: nil,
            filesScanned: 0,
            bytesRead: 0,
            elapsedMs: 0
        )
        let used = ProviderSnapshot(
            provider: .claude,
            planId: "claude-pro",
            windows: [UsageWindow(kind: .hours5, inputTokens: 9, outputTokens: 1, cacheReadTokens: 0, eventCount: 1)],
            lastEventAt: nil,
            filesScanned: 1,
            bytesRead: 1,
            elapsedMs: 1
        )
        let snap = UsageSnapshot(capturedAt: Date(), providers: [empty, used], scanMs: 1)
        let entries = Exporter.ladderEntries(from: snap, displayName: "cardozo")
        #expect(entries.count == 1)
        #expect(entries[0].planId == "claude-pro")
        #expect(entries[0].displayName == "cardozo")
    }
}

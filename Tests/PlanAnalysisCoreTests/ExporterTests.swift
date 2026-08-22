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
                    planLabel: "Claude Pro",
                    planSource: .scanned,
                    windows: [
                        UsageWindow(kind: .hours5, inputTokens: 10, outputTokens: 2, cacheReadTokens: 1, eventCount: 1, equivUsd: 0.12)
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
        #expect(csv.contains("provider,plan_id,plan_label"))
        #expect(csv.contains("claude,claude-pro,Claude Pro,scanned,5h,10,2,1,0.1200,1"))
    }

    @Test
    func ladderOnlyUploadsScannedSubscriptions() {
        let unknown = ProviderSnapshot(
            provider: .claude,
            planId: "",
            planSource: .unknown,
            windows: [UsageWindow(kind: .month, inputTokens: 9, outputTokens: 1, cacheReadTokens: 0, eventCount: 1, equivUsd: 1)],
            lastEventAt: nil,
            filesScanned: 1,
            bytesRead: 1,
            elapsedMs: 1
        )
        let scanned = ProviderSnapshot(
            provider: .codex,
            planId: "gpt-pro-20x",
            planLabel: "ChatGPT Pro",
            planSource: .scanned,
            windows: [UsageWindow(kind: .month, inputTokens: 9, outputTokens: 1, cacheReadTokens: 0, eventCount: 1, equivUsd: 2.5)],
            lastEventAt: nil,
            filesScanned: 1,
            bytesRead: 1,
            elapsedMs: 1
        )
        let snap = UsageSnapshot(capturedAt: Date(), providers: [unknown, scanned], scanMs: 1)
        let entries = Exporter.ladderEntries(from: snap, displayName: "cardozo")
        #expect(entries.count == 1)
        #expect(entries[0].planId == "gpt-pro-20x")
        #expect(entries[0].equivUsd == 2.5)
        #expect(entries[0].window == "30d")
    }
}

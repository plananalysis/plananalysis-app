import Foundation

public struct ScanRoots: Sendable {
    public var claude: [URL]
    public var codex: [URL]

    public init(claude: [URL], codex: [URL]) {
        self.claude = claude
        self.codex = codex
    }

    public static func `default`(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> ScanRoots {
        ScanRoots(
            claude: [
                home.appendingPathComponent(".claude/projects"),
                home.appendingPathComponent(".config/claude/projects"),
            ],
            codex: [
                home.appendingPathComponent(".codex/sessions"),
                home.appendingPathComponent(".codex/archived_sessions"),
            ]
        )
    }
}

public struct LocalLogScanner: Sendable {
    public var roots: ScanRoots
    public var now: Date

    public init(roots: ScanRoots = .default(), now: Date = Date()) {
        self.roots = roots
        self.now = now
    }

    public func scan(provider: ProviderID, planId: String, store: CursorStore, deltas: DeltaStore) -> ProviderSnapshot {
        let start = DispatchTime.now()
        var fresh: [TokenDelta] = []
        var files = 0
        var bytes = 0
        for dir in directories(for: provider) {
            for file in jsonlFiles(in: dir) {
                files += 1
                let path = file.path
                do {
                    let result = try IncrementalJSONL.readNewLines(url: file, cursor: store.cursor(for: path))
                    store.setCursor(result.cursor, for: path)
                    bytes += result.bytesRead
                    for line in result.lines {
                        fresh.append(contentsOf: TokenExtractor.deltas(fromJSONLine: line, provider: provider))
                    }
                } catch {
                    continue
                }
            }
        }
        deltas.append(fresh, provider: provider)
        deltas.prune(olderThan: now.addingTimeInterval(-30 * 24 * 3600))
        store.save()
        deltas.save()
        let all = deltas.deltas(for: provider)
        let elapsed = Int(DispatchTime.now().uptimeNanoseconds.subtractingReportingOverflow(start.uptimeNanoseconds).partialValue / 1_000_000)
        return ProviderSnapshot(
            provider: provider,
            planId: planId,
            windows: UsageAggregator.windows(from: all, now: now),
            lastEventAt: all.map(\.at).max(),
            filesScanned: files,
            bytesRead: bytes,
            elapsedMs: elapsed
        )
    }

    public func scanAll(store: CursorStore, deltas: DeltaStore, planIds: [ProviderID: String]) -> UsageSnapshot {
        let start = DispatchTime.now()
        let providers = ProviderID.allCases.map { id in
            scan(provider: id, planId: planIds[id] ?? defaultPlan(id), store: store, deltas: deltas)
        }
        let elapsed = Int(DispatchTime.now().uptimeNanoseconds.subtractingReportingOverflow(start.uptimeNanoseconds).partialValue / 1_000_000)
        return UsageSnapshot(capturedAt: now, providers: providers, scanMs: elapsed)
    }

    private func directories(for provider: ProviderID) -> [URL] {
        switch provider {
        case .claude: return roots.claude
        case .codex: return roots.codex
        }
    }

    private func jsonlFiles(in directory: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }
        var out: [URL] = []
        for case let url as URL in enumerator {
            if url.pathExtension == "jsonl" {
                out.append(url)
            }
        }
        return out
    }

    private func defaultPlan(_ id: ProviderID) -> String {
        switch id {
        case .claude: return "claude-pro"
        case .codex: return "gpt-plus"
        }
    }
}

import Foundation

/// Compact append-only token events. JSONL cursors skip old bytes; this keeps window math correct.
public final class DeltaStore: @unchecked Sendable {
    private let url: URL
    private var map: [ProviderID: [TokenDelta]]
    private let lock = NSLock()

    public init(url: URL) {
        self.url = url
        if let data = try? Data(contentsOf: url) {
            let dec = JSONDecoder()
            dec.dateDecodingStrategy = .iso8601
            if let decoded = try? dec.decode([ProviderID: [TokenDelta]].self, from: data) {
                self.map = decoded
                return
            }
        }
        self.map = [:]
    }

    public static func applicationSupport() -> DeltaStore {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PlanAnalysis", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return DeltaStore(url: root.appendingPathComponent("deltas.json"))
    }

    public func append(_ deltas: [TokenDelta], provider: ProviderID) {
        guard !deltas.isEmpty else { return }
        lock.lock()
        map[provider, default: []].append(contentsOf: deltas)
        lock.unlock()
    }

    public func deltas(for provider: ProviderID) -> [TokenDelta] {
        lock.lock()
        defer { lock.unlock() }
        return map[provider] ?? []
    }

    public func prune(olderThan cutoff: Date) {
        lock.lock()
        for key in map.keys {
            map[key]?.removeAll { $0.at < cutoff }
        }
        lock.unlock()
    }

    public func save() {
        lock.lock()
        let snapshot = map
        lock.unlock()
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        if let data = try? enc.encode(snapshot) {
            try? data.write(to: url, options: .atomic)
        }
    }
}

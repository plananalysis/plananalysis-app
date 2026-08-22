import Foundation

/// Persistent per-file read cursors. Avoids rescanning multi-GB JSONL trees.
public final class CursorStore: @unchecked Sendable {
    private let url: URL
    private var map: [String: FileCursor]
    private let lock = NSLock()

    public init(url: URL) {
        self.url = url
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([String: FileCursor].self, from: data) {
            self.map = decoded
        } else {
            self.map = [:]
        }
    }

    public static func applicationSupport() -> CursorStore {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PlanAnalysis", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return CursorStore(url: root.appendingPathComponent("cursors.json"))
    }

    public func cursor(for path: String) -> FileCursor? {
        lock.lock()
        defer { lock.unlock() }
        return map[path]
    }

    public func setCursor(_ cursor: FileCursor, for path: String) {
        lock.lock()
        map[path] = cursor
        lock.unlock()
    }

    public func save() {
        lock.lock()
        let snapshot = map
        lock.unlock()
        if let data = try? JSONEncoder().encode(snapshot) {
            try? data.write(to: url, options: .atomic)
        }
    }
}

import Foundation
import CoreServices

/// Recursive FSEvents watcher. One coalesced callback per burst, not per file write.
public final class FileWatcher: @unchecked Sendable {
    private var stream: FSEventStreamRef?
    public var onChange: (@Sendable () -> Void)?

    public init() {}

    deinit { stop() }

    public func watch(directories: [URL]) {
        stop()
        let existing = directories.filter { FileManager.default.fileExists(atPath: $0.path) }.map(\.path)
        guard !existing.isEmpty else { return }
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        let callback: FSEventStreamCallback = { _, info, _, _, _, _ in
            guard let info else { return }
            let watcher = Unmanaged<FileWatcher>.fromOpaque(info).takeUnretainedValue()
            watcher.onChange?()
        }
        guard let created = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            existing as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.25,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer)
        ) else { return }
        stream = created
        FSEventStreamSetDispatchQueue(created, DispatchQueue(label: "ai.plananalysis.fsevents", qos: .utility))
        FSEventStreamStart(created)
    }

    public func stop() {
        guard let stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }
}

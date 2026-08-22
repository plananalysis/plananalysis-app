import Foundation

public enum IncrementalJSONL {
    public struct Result: Sendable {
        public var lines: [String]
        public var cursor: FileCursor
        public var bytesRead: Int
        public var reused: Bool
    }

    public static func stat(_ url: URL) throws -> (inode: UInt64, size: UInt64) {
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = (attrs[.size] as? NSNumber)?.uint64Value ?? 0
        let inode = (attrs[.systemFileNumber] as? NSNumber)?.uint64Value ?? 0
        return (inode, size)
    }

    public static func readNewLines(url: URL, cursor: FileCursor?) throws -> Result {
        let (inode, size) = try stat(url)
        var start: UInt64 = 0
        var reused = false
        if let cursor, cursor.inode == inode, cursor.size <= size, cursor.offset <= size {
            start = cursor.offset
            reused = cursor.offset > 0
        }

        if start == size {
            return Result(
                lines: [],
                cursor: FileCursor(inode: inode, size: size, offset: start),
                bytesRead: 0,
                reused: true
            )
        }

        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        try handle.seek(toOffset: start)
        let data = handle.readDataToEndOfFile()
        var offset = start + UInt64(data.count)
        var slice = data
        // A write may land mid-line. Keep an incomplete tail for the next pass.
        if let last = data.last, last != 0x0A {
            if let nl = data.lastIndex(of: 0x0A) {
                slice = data.prefix(upTo: nl + 1)
                offset = start + UInt64(slice.count)
            } else {
                return Result(
                    lines: [],
                    cursor: FileCursor(inode: inode, size: size, offset: start),
                    bytesRead: 0,
                    reused: reused
                )
            }
        }
        let text = String(decoding: slice, as: UTF8.self)
        let lines = text.split(whereSeparator: \.isNewline).map(String.init)
        return Result(
            lines: lines,
            cursor: FileCursor(inode: inode, size: size, offset: offset),
            bytesRead: slice.count,
            reused: reused
        )
    }
}

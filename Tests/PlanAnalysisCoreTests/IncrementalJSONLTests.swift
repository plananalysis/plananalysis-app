import Foundation
import Testing
@testable import PlanAnalysisCore

@Suite
struct IncrementalJSONLTests {
    @Test
    func firstReadThenOnlyNewBytes() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("a.jsonl")
        try "one\n".write(to: file, atomically: true, encoding: .utf8)

        let first = try IncrementalJSONL.readNewLines(url: file, cursor: nil)
        #expect(first.lines == ["one"])
        #expect(first.reused == false)

        let unchanged = try IncrementalJSONL.readNewLines(url: file, cursor: first.cursor)
        #expect(unchanged.lines.isEmpty)
        #expect(unchanged.bytesRead == 0)
        #expect(unchanged.reused == true)

        let handle = try FileHandle(forWritingTo: file)
        try handle.seekToEnd()
        try handle.write(contentsOf: Data("two\n".utf8))
        try handle.close()

        let second = try IncrementalJSONL.readNewLines(url: file, cursor: first.cursor)
        #expect(second.lines == ["two"])
        #expect(second.bytesRead == 4)
        #expect(second.reused == true)
    }

    @Test
    func incompleteTailIsHeld() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("b.jsonl")
        try Data("partial".utf8).write(to: file)

        let first = try IncrementalJSONL.readNewLines(url: file, cursor: nil)
        #expect(first.lines.isEmpty)
        #expect(first.cursor.offset == 0)

        let handle = try FileHandle(forWritingTo: file)
        try handle.seekToEnd()
        try handle.write(contentsOf: Data("-line\nnext\n".utf8))
        try handle.close()

        let second = try IncrementalJSONL.readNewLines(url: file, cursor: first.cursor)
        #expect(second.lines == ["partial-line", "next"])
    }
}

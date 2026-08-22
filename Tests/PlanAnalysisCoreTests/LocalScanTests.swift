import Foundation
import Testing
@testable import PlanAnalysisCore

@Suite
struct LocalScanTests {
    @Test
    func secondScanReadsOnlyNewBytesAndKeepsWindow() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let claude = root.appendingPathComponent("claude")
        try FileManager.default.createDirectory(at: claude, withIntermediateDirectories: true)
        let file = claude.appendingPathComponent("s.jsonl")
        let ts = ISO8601DateFormatter().string(from: Date())
        let line = #"{"type":"assistant","timestamp":"\#(ts)","message":{"usage":{"input_tokens":100,"output_tokens":5}}}"# + "\n"
        try line.write(to: file, atomically: true, encoding: .utf8)

        let cursorURL = root.appendingPathComponent("cursors.json")
        let deltaURL = root.appendingPathComponent("deltas.json")
        let store = CursorStore(url: cursorURL)
        let deltas = DeltaStore(url: deltaURL)
        let scanner = LocalLogScanner(roots: ScanRoots(claude: [claude], codex: []), now: Date())

        let first = scanner.scan(provider: .claude, planId: "claude-pro", store: store, deltas: deltas)
        #expect(first.window(.hours5).inputTokens == 100)
        #expect(first.bytesRead > 0)

        let second = scanner.scan(provider: .claude, planId: "claude-pro", store: store, deltas: deltas)
        #expect(second.window(.hours5).inputTokens == 100)
        #expect(second.bytesRead == 0)

        let handle = try FileHandle(forWritingTo: file)
        try handle.seekToEnd()
        try handle.write(contentsOf: Data(#"{"type":"assistant","timestamp":"\#(ts)","message":{"usage":{"input_tokens":20,"output_tokens":1}}}"#.utf8 + Data([0x0A])))
        try handle.close()

        let third = scanner.scan(provider: .claude, planId: "claude-pro", store: store, deltas: deltas)
        #expect(third.window(.hours5).inputTokens == 120)
        #expect(third.bytesRead > 0)
    }
}

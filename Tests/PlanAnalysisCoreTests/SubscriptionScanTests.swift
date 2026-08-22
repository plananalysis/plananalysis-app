import Foundation
import Testing
@testable import PlanAnalysisCore

@Suite
struct SubscriptionScanTests {
    @Test
    func readsChatGPTPlanFromCodexAuthJSON() throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: home.appendingPathComponent(".codex"), withIntermediateDirectories: true)
        let payload = #"{"email":"a@b.com","https://api.openai.com/auth":{"chatgpt_plan_type":"plus"}}"#
        let b64 = Data(payload.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let auth = #"{"tokens":{"id_token":"aaa.\#(b64).ccc"}}"#
        try auth.write(to: home.appendingPathComponent(".codex/auth.json"), atomically: true, encoding: .utf8)
        let sub = SubscriptionScanner.scanCodex(home: home)
        #expect(sub?.planId == "gpt-plus")
        #expect(sub?.email == "a@b.com")
        #expect(sub?.source == "codex-auth.json")
    }
}

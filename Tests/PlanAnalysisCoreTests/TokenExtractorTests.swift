import Foundation
import Testing
@testable import PlanAnalysisCore

@Suite
struct TokenExtractorTests {
    @Test
    func claudeAssistantUsage() {
        let line = #"{"type":"assistant","timestamp":"2026-08-09T07:41:12.813Z","message":{"usage":{"input_tokens":10,"output_tokens":3,"cache_read_input_tokens":5}}}"#
        let deltas = TokenExtractor.deltas(fromJSONLine: line, provider: .claude)
        #expect(deltas.count == 1)
        #expect(deltas[0].input == 10)
        #expect(deltas[0].output == 3)
        #expect(deltas[0].cacheRead == 5)
    }

    @Test
    func claudeUserIgnored() {
        let line = #"{"type":"user","message":{"usage":{"input_tokens":99}}}"#
        #expect(TokenExtractor.deltas(fromJSONLine: line, provider: .claude).isEmpty)
    }

    @Test
    func codexUsesLastTokenUsageNotTotal() {
        let line = #"{"timestamp":"2026-07-20T14:54:21.030Z","type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"input_tokens":1000,"output_tokens":50},"last_token_usage":{"input_tokens":40,"output_tokens":7,"reasoning_output_tokens":3,"cached_input_tokens":12}}}}"#
        let deltas = TokenExtractor.deltas(fromJSONLine: line, provider: .codex)
        #expect(deltas.count == 1)
        #expect(deltas[0].input == 40)
        #expect(deltas[0].output == 10)
        #expect(deltas[0].cacheRead == 12)
    }
}

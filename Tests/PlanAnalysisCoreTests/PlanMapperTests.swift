import Foundation
import Testing
@testable import PlanAnalysisCore

@Suite
struct PlanMapperTests {
    @Test
    func claudeMaxTiers() {
        #expect(PlanMapper.claude(subscriptionType: "max", rateLimitTier: "default_claude_max_20x")?.planId == "claude-max20")
        #expect(PlanMapper.claude(subscriptionType: "max", rateLimitTier: "default_claude_max_5x")?.planId == "claude-max5")
        #expect(PlanMapper.claude(subscriptionType: "pro", rateLimitTier: nil)?.planId == "claude-pro")
    }

    @Test
    func chatgptAndCursor() {
        #expect(PlanMapper.chatgpt(planType: "plus")?.planId == "gpt-plus")
        #expect(PlanMapper.chatgpt(planType: "pro")?.planId == "gpt-pro-20x")
        #expect(PlanMapper.cursor(membership: "ultra")?.planId == "cursor-ultra")
        #expect(PlanMapper.cursor(membership: "pro_plus")?.planId == "cursor-proplus")
    }
}

@Suite
struct PricingTests {
    @Test
    func sonnetCostsPositive() {
        let d = TokenDelta(at: Date(), input: 1_000_000, output: 0, cacheRead: 0, model: "claude-sonnet-4-6")
        #expect(Pricing.costUsd(d) == 3)
    }

    @Test
    func unknownModelIsZero() {
        let d = TokenDelta(at: Date(), input: 1_000_000, output: 0, model: "mystery-model")
        #expect(Pricing.costUsd(d) == 0)
    }
}

@Suite
struct JWTTests {
    @Test
    func payloadReadsPlanClaim() {
        // header.payload.sig — payload is {"https://api.openai.com/auth":{"chatgpt_plan_type":"plus"}}
        let payload = #"{"https://api.openai.com/auth":{"chatgpt_plan_type":"plus"}}"#
        let b64 = Data(payload.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let token = "aaa.\(b64).ccc"
        let obj = JWT.payload(token)
        let auth = obj?["https://api.openai.com/auth"] as? [String: Any]
        #expect(auth?["chatgpt_plan_type"] as? String == "plus")
    }
}

import Foundation
import Security
import SQLite3

public enum SubscriptionScanner {
    public static func scan(home: URL = FileManager.default.homeDirectoryForCurrentUser) async -> [ProviderID: Subscription] {
        async let claude = scanClaude()
        async let codex = scanCodex(home: home)
        async let cursor = scanCursor(home: home)
        var out: [ProviderID: Subscription] = [:]
        if let s = await claude { out[.claude] = s }
        if let s = await codex { out[.codex] = s }
        if let s = await cursor { out[.cursor] = s }
        return out
    }

    static func scanCodex(home: URL) -> Subscription? {
        let url = home.appendingPathComponent(".codex/auth.json")
        guard let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        let tokens = obj["tokens"] as? [String: Any] ?? [:]
        let idToken = tokens["id_token"] as? String
        guard let payload = idToken.flatMap(JWT.payload) else { return nil }
        let auth = payload["https://api.openai.com/auth"] as? [String: Any]
        let plan = auth?["chatgpt_plan_type"] as? String
        var sub = PlanMapper.chatgpt(planType: plan)
        sub?.email = payload["email"] as? String
        sub?.source = "codex-auth.json"
        return sub
    }

    static func scanCursor(home: URL) -> Subscription? {
        let db = home
            .appendingPathComponent("Library/Application Support/Cursor/User/globalStorage/state.vscdb")
        guard FileManager.default.fileExists(atPath: db.path) else { return nil }
        let membership = sqliteString(db: db, key: "cursorAuth/stripeMembershipType")
        let email = sqliteString(db: db, key: "cursorAuth/cachedEmail")
        var sub = PlanMapper.cursor(membership: membership)
        sub?.email = email
        sub?.source = "cursor.app"
        return sub
    }

    static func scanClaude() async -> Subscription? {
        guard let token = claudeAccessToken() else { return nil }
        var req = URLRequest(url: URL(string: "https://api.anthropic.com/api/oauth/usage")!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        req.setValue("plananalysis-app/0.1", forHTTPHeaderField: "User-Agent")
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              let http = resp as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        let type = string(obj["subscriptionType"] ?? obj["subscription_type"])
        let tier = string(obj["rate_limit_tier"] ?? obj["rateLimitTier"])
        var sub = PlanMapper.claude(subscriptionType: type, rateLimitTier: tier)
        sub?.source = "claude-oauth"
        return sub
    }

    private static func claudeAccessToken() -> String? {
        guard let data = genericPassword(service: "Claude Code-credentials"),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        if let oauth = obj["claudeAiOauth"] as? [String: Any],
           let token = oauth["accessToken"] as? String,
           !token.isEmpty {
            return token
        }
        return obj["accessToken"] as? String
    }

    private static func genericPassword(service: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var out: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &out)
        guard status == errSecSuccess else { return nil }
        return out as? Data
    }

    private static func sqliteString(db: URL, key: String) -> String? {
        var handle: OpaquePointer?
        let uri = "file:\(db.path)?mode=ro"
        guard sqlite3_open_v2(uri, &handle, SQLITE_OPEN_READONLY | SQLITE_OPEN_URI, nil) == SQLITE_OK else {
            sqlite3_close(handle)
            return nil
        }
        defer { sqlite3_close(handle) }
        var stmt: OpaquePointer?
        let sql = "SELECT value FROM ItemTable WHERE key = ?"
        guard sqlite3_prepare_v2(handle, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, key, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        guard sqlite3_step(stmt) == SQLITE_ROW, let c = sqlite3_column_text(stmt, 0) else { return nil }
        return String(cString: c)
    }

    private static func string(_ value: Any?) -> String? {
        switch value {
        case let s as String: return s
        default: return nil
        }
    }
}

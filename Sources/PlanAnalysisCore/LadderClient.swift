import Foundation

public struct LadderUploadResult: Sendable {
    public var accepted: Int
    public var detailURLs: [URL]
}

public struct LadderClient: Sendable {
    public var baseURL: URL
    public var session: URLSession

    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    public func upload(_ entries: [LadderEntry]) async throws -> LadderUploadResult {
        var req = URLRequest(url: baseURL.appending(path: "v1/ladder"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("plananalysis-app/0.1", forHTTPHeaderField: "User-Agent")
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        req.httpBody = try enc.encode(UploadBody(entries: entries))
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw LadderError.http((resp as? HTTPURLResponse)?.statusCode ?? -1)
        }
        let decoded = try JSONDecoder().decode(UploadResponse.self, from: data)
        return LadderUploadResult(
            accepted: decoded.accepted,
            detailURLs: decoded.plans.compactMap { URL(string: $0.detailURL) }
        )
    }

    public enum LadderError: Error {
        case http(Int)
    }

    private struct UploadBody: Codable {
        var entries: [LadderEntry]
    }

    private struct UploadResponse: Codable {
        var accepted: Int
        var plans: [PlanRef]
    }

    private struct PlanRef: Codable {
        var planId: String
        var detailURL: String
    }
}

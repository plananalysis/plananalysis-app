import Foundation

public enum ProviderID: String, Codable, Sendable, CaseIterable {
    case claude
    case codex
    case cursor
}

public enum WindowKind: String, Codable, Sendable, CaseIterable {
    case hours5 = "5h"
    case week = "7d"
    case month = "30d"
}

public enum PlanSource: String, Codable, Sendable {
    case scanned
    case unknown
}

public struct TokenDelta: Codable, Sendable, Equatable {
    public var at: Date
    public var input: Int
    public var output: Int
    public var cacheRead: Int
    public var cacheCreate: Int
    public var model: String?

    public init(at: Date, input: Int, output: Int, cacheRead: Int = 0, cacheCreate: Int = 0, model: String? = nil) {
        self.at = at
        self.input = input
        self.output = output
        self.cacheRead = cacheRead
        self.cacheCreate = cacheCreate
        self.model = model
    }

    public var billedInput: Int { max(0, input) }
    public var total: Int { billedInput + output + cacheRead + cacheCreate }
}

public struct UsageWindow: Codable, Sendable, Equatable {
    public var kind: WindowKind
    public var inputTokens: Int
    public var outputTokens: Int
    public var cacheReadTokens: Int
    public var eventCount: Int
    public var equivUsd: Double

    public init(
        kind: WindowKind,
        inputTokens: Int,
        outputTokens: Int,
        cacheReadTokens: Int,
        eventCount: Int,
        equivUsd: Double = 0
    ) {
        self.kind = kind
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheReadTokens = cacheReadTokens
        self.eventCount = eventCount
        self.equivUsd = equivUsd
    }

    public var totalTokens: Int { inputTokens + outputTokens + cacheReadTokens }
}

public struct Subscription: Codable, Sendable, Equatable {
    public var provider: ProviderID
    public var planId: String
    public var planLabel: String
    public var email: String?
    public var source: String
    public var rawTier: String?

    public init(
        provider: ProviderID,
        planId: String,
        planLabel: String,
        email: String?,
        source: String,
        rawTier: String?
    ) {
        self.provider = provider
        self.planId = planId
        self.planLabel = planLabel
        self.email = email
        self.source = source
        self.rawTier = rawTier
    }
}

public struct ProviderSnapshot: Codable, Sendable, Equatable {
    public var provider: ProviderID
    public var planId: String
    public var planLabel: String
    public var planSource: PlanSource
    public var subscriptionEmail: String?
    public var windows: [UsageWindow]
    public var lastEventAt: Date?
    public var filesScanned: Int
    public var bytesRead: Int
    public var elapsedMs: Int

    public init(
        provider: ProviderID,
        planId: String,
        planLabel: String = "",
        planSource: PlanSource = .unknown,
        subscriptionEmail: String? = nil,
        windows: [UsageWindow],
        lastEventAt: Date?,
        filesScanned: Int,
        bytesRead: Int,
        elapsedMs: Int
    ) {
        self.provider = provider
        self.planId = planId
        self.planLabel = planLabel
        self.planSource = planSource
        self.subscriptionEmail = subscriptionEmail
        self.windows = windows
        self.lastEventAt = lastEventAt
        self.filesScanned = filesScanned
        self.bytesRead = bytesRead
        self.elapsedMs = elapsedMs
    }

    public func window(_ kind: WindowKind) -> UsageWindow {
        windows.first(where: { $0.kind == kind })
            ?? UsageWindow(kind: kind, inputTokens: 0, outputTokens: 0, cacheReadTokens: 0, eventCount: 0)
    }

    public var canUpload: Bool {
        guard planSource == .scanned, !planId.isEmpty else { return false }
        let month = window(.month)
        return month.totalTokens > 0 || month.equivUsd > 0 || provider == .cursor
    }
}

public struct UsageSnapshot: Codable, Sendable, Equatable {
    public var capturedAt: Date
    public var providers: [ProviderSnapshot]
    public var scanMs: Int

    public init(capturedAt: Date, providers: [ProviderSnapshot], scanMs: Int) {
        self.capturedAt = capturedAt
        self.providers = providers
        self.scanMs = scanMs
    }
}

public struct LadderEntry: Codable, Sendable, Equatable {
    public var planId: String
    public var provider: String
    public var displayName: String
    public var window: String
    public var inputTokens: Int
    public var outputTokens: Int
    public var cacheReadTokens: Int
    public var equivUsd: Double
    public var capturedAt: Date

    public init(
        planId: String,
        provider: String,
        displayName: String,
        window: String,
        inputTokens: Int,
        outputTokens: Int,
        cacheReadTokens: Int,
        equivUsd: Double,
        capturedAt: Date
    ) {
        self.planId = planId
        self.provider = provider
        self.displayName = displayName
        self.window = window
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheReadTokens = cacheReadTokens
        self.equivUsd = equivUsd
        self.capturedAt = capturedAt
    }
}

public struct FileCursor: Codable, Sendable, Equatable {
    public var inode: UInt64
    public var size: UInt64
    public var offset: UInt64

    public init(inode: UInt64, size: UInt64, offset: UInt64) {
        self.inode = inode
        self.size = size
        self.offset = offset
    }
}

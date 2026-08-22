import Foundation

public enum ProviderID: String, Codable, Sendable, CaseIterable {
    case claude
    case codex
}

public enum WindowKind: String, Codable, Sendable, CaseIterable {
    case hours5 = "5h"
    case week = "7d"
    case month = "30d"
}

public struct TokenDelta: Codable, Sendable, Equatable {
    public var at: Date
    public var input: Int
    public var output: Int
    public var cacheRead: Int
    public var cacheCreate: Int

    public init(at: Date, input: Int, output: Int, cacheRead: Int = 0, cacheCreate: Int = 0) {
        self.at = at
        self.input = input
        self.output = output
        self.cacheRead = cacheRead
        self.cacheCreate = cacheCreate
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

    public init(kind: WindowKind, inputTokens: Int, outputTokens: Int, cacheReadTokens: Int, eventCount: Int) {
        self.kind = kind
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheReadTokens = cacheReadTokens
        self.eventCount = eventCount
    }

    public var totalTokens: Int { inputTokens + outputTokens + cacheReadTokens }
}

public struct ProviderSnapshot: Codable, Sendable, Equatable {
    public var provider: ProviderID
    public var planId: String
    public var windows: [UsageWindow]
    public var lastEventAt: Date?
    public var filesScanned: Int
    public var bytesRead: Int
    public var elapsedMs: Int

    public init(
        provider: ProviderID,
        planId: String,
        windows: [UsageWindow],
        lastEventAt: Date?,
        filesScanned: Int,
        bytesRead: Int,
        elapsedMs: Int
    ) {
        self.provider = provider
        self.planId = planId
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
    public var capturedAt: Date

    public init(
        planId: String,
        provider: String,
        displayName: String,
        window: String,
        inputTokens: Int,
        outputTokens: Int,
        cacheReadTokens: Int,
        capturedAt: Date
    ) {
        self.planId = planId
        self.provider = provider
        self.displayName = displayName
        self.window = window
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheReadTokens = cacheReadTokens
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

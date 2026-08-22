import Foundation

public actor RefreshCoordinator {
    private let store: CursorStore
    private let deltas: DeltaStore
    private var scanner: LocalLogScanner
    private var planIds: [ProviderID: String]
    public private(set) var latest: UsageSnapshot?

    public init(
        store: CursorStore,
        deltas: DeltaStore,
        roots: ScanRoots = .default(),
        planIds: [ProviderID: String] = [:]
    ) {
        self.store = store
        self.deltas = deltas
        self.scanner = LocalLogScanner(roots: roots)
        self.planIds = planIds
    }

    public func setPlan(_ planId: String, for provider: ProviderID) {
        planIds[provider] = planId
    }

    public func refresh() -> UsageSnapshot {
        var next = scanner
        next.now = Date()
        let snap = next.scanAll(store: store, deltas: deltas, planIds: planIds)
        latest = snap
        return snap
    }
}

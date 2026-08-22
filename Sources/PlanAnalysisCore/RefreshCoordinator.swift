import Foundation

public actor RefreshCoordinator {
    private let store: CursorStore
    private let deltas: DeltaStore
    private var scanner: LocalLogScanner
    private var subscriptions: [ProviderID: Subscription] = [:]
    private var subscriptionsAt: Date?
    public private(set) var latest: UsageSnapshot?

    public init(store: CursorStore, deltas: DeltaStore, roots: ScanRoots = .default()) {
        self.store = store
        self.deltas = deltas
        self.scanner = LocalLogScanner(roots: roots)
    }

    public func refresh() async -> UsageSnapshot {
        if subscriptionsAt == nil || Date().timeIntervalSince(subscriptionsAt!) > 900 {
            subscriptions = await SubscriptionScanner.scan()
            subscriptionsAt = Date()
        }
        var next = scanner
        next.now = Date()
        let snap = next.scanAll(store: store, deltas: deltas, subscriptions: subscriptions)
        latest = snap
        return snap
    }
}

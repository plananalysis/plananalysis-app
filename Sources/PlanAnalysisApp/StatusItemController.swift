import AppKit
import PlanAnalysisCore

@MainActor
final class StatusItemController {
    private let item: NSStatusItem
    private let meter: MeterView
    var onExportJSON: (() -> Void)?
    var onExportCSV: (() -> Void)?
    var onUpload: (() -> Void)?
    var onQuit: (() -> Void)?

    init() {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        meter = MeterView(frame: NSRect(x: 0, y: 0, width: 36, height: 18))
        item.button?.addSubview(meter)
        item.button?.frame = meter.frame
        item.button?.imagePosition = .noImage
        rebuildMenu(snapshot: nil)
    }

    func update(_ snapshot: UsageSnapshot) {
        meter.ratios = snapshot.providers.prefix(3).map { p in
            min(1, log10(1 + p.window(.month).equivUsd * 10) / 4.0)
        }
        rebuildMenu(snapshot: snapshot)
    }

    private func rebuildMenu(snapshot: UsageSnapshot?) {
        let menu = NSMenu()
        menu.autoenablesItems = false
        if let snapshot {
            for p in snapshot.providers {
                let w = p.window(.month)
                let label = p.planLabel.isEmpty ? p.provider.rawValue.capitalized : p.planLabel
                let badge = p.planSource == .scanned ? "scanned" : "no subscription"
                let title = "\(label)  \(money(w.equivUsd)) / 30d  · \(badge)"
                let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
                let sub = NSMenuItem(
                    title: "  5h \(fmt(p.window(.hours5).totalTokens)) · 30d \(fmt(w.totalTokens)) tok · \(p.elapsedMs)ms",
                    action: nil,
                    keyEquivalent: ""
                )
                sub.isEnabled = false
                menu.addItem(sub)
            }
            let scan = NSMenuItem(title: "Scan \(snapshot.scanMs) ms", action: nil, keyEquivalent: "")
            scan.isEnabled = false
            menu.addItem(scan)
        } else {
            let loading = NSMenuItem(title: "Scanning subscriptions…", action: nil, keyEquivalent: "")
            loading.isEnabled = false
            menu.addItem(loading)
        }
        menu.addItem(.separator())
        menu.addItem(actionItem("Export JSON…", #selector(exportJSON)))
        menu.addItem(actionItem("Export CSV…", #selector(exportCSV)))
        menu.addItem(actionItem("Upload scanned samples…", #selector(upload)))
        menu.addItem(.separator())
        menu.addItem(actionItem("Quit Plan Analysis", #selector(quit), key: "q"))
        item.menu = menu
    }

    private func actionItem(_ title: String, _ sel: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: sel, keyEquivalent: key)
        item.target = self
        return item
    }

    @objc private func exportJSON() { onExportJSON?() }
    @objc private func exportCSV() { onExportCSV?() }
    @objc private func upload() { onUpload?() }
    @objc private func quit() { onQuit?() }

    private func fmt(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 1_000 { return String(format: "%.1fk", Double(n) / 1_000) }
        return "\(n)"
    }

    private func money(_ usd: Double) -> String {
        String(format: "$%.2f", usd)
    }
}

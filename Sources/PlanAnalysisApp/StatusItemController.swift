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
        meter.ratios = snapshot.providers.prefix(2).map { p in
            let w = p.window(.hours5)
            // Local-only: intensity bar, not a vendor quota. Log-scaled to stay readable.
            let t = Double(w.totalTokens)
            return min(1, log10(1 + t) / 7.0)
        }
        rebuildMenu(snapshot: snapshot)
    }

    private func rebuildMenu(snapshot: UsageSnapshot?) {
        let menu = NSMenu()
        menu.autoenablesItems = false
        if let snapshot {
            for p in snapshot.providers {
                let w5 = p.window(.hours5)
                let w7 = p.window(.week)
                let title = "\(p.provider.rawValue.capitalized)  5h \(fmt(w5.totalTokens))   7d \(fmt(w7.totalTokens))"
                let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
                let sub = NSMenuItem(
                    title: "  in \(fmt(w5.inputTokens)) · out \(fmt(w5.outputTokens)) · cache \(fmt(w5.cacheReadTokens)) · \(p.elapsedMs)ms / \(p.filesScanned) files",
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
            let loading = NSMenuItem(title: "Scanning local usage…", action: nil, keyEquivalent: "")
            loading.isEnabled = false
            menu.addItem(loading)
        }
        menu.addItem(.separator())
        menu.addItem(actionItem("Export JSON…", #selector(exportJSON)))
        menu.addItem(actionItem("Export CSV…", #selector(exportCSV)))
        menu.addItem(actionItem("Upload to Plan Analysis ladder…", #selector(upload)))
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
}

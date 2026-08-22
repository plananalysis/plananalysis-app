import AppKit
import PlanAnalysisCore
import UniformTypeIdentifiers

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var status: StatusItemController?
    private var watcher: FileWatcher?
    private var coordinator: RefreshCoordinator?
    private var refreshTask: Task<Void, Never>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let roots = ScanRoots.default()
        let store = CursorStore.applicationSupport()
        let deltas = DeltaStore.applicationSupport()
        let coordinator = RefreshCoordinator(store: store, deltas: deltas, roots: roots)
        self.coordinator = coordinator

        let status = StatusItemController()
        status.onExportJSON = { [weak self] in self?.export(ext: "json") }
        status.onExportCSV = { [weak self] in self?.export(ext: "csv") }
        status.onUpload = { [weak self] in self?.uploadLadder() }
        status.onQuit = { NSApp.terminate(nil) }
        self.status = status

        let watcher = FileWatcher()
        watcher.onChange = { [weak self] in
            Task { @MainActor in self?.scheduleRefresh() }
        }
        watcher.watch(directories: roots.claude + roots.codex)
        self.watcher = watcher

        scheduleRefresh()
    }

    private func scheduleRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self, let coordinator else { return }
            let snap = await coordinator.refresh()
            guard !Task.isCancelled else { return }
            self.status?.update(snap)
        }
    }

    private func latestSnapshot() async -> UsageSnapshot? {
        if let latest = await coordinator?.latest { return latest }
        return await coordinator?.refresh()
    }

    private func export(ext: String) {
        Task {
            guard let snap = await latestSnapshot() else { return }
            let panel = NSSavePanel()
            panel.allowedContentTypes = ext == "json" ? [.json] : [.commaSeparatedText]
            panel.nameFieldStringValue = "plananalysis-usage.\(ext)"
            guard panel.runModal() == .OK, let url = panel.url else { return }
            do {
                if ext == "json" {
                    try Exporter.jsonData(from: snap).write(to: url)
                } else {
                    try Exporter.csvString(from: snap).write(to: url, atomically: true, encoding: .utf8)
                }
            } catch {
                present(error.localizedDescription)
            }
        }
    }

    private func uploadLadder() {
        Task {
            guard let snap = await latestSnapshot() else { return }
            let name = UserDefaults.standard.string(forKey: "displayName")?.trimmingCharacters(in: .whitespacesAndNewlines)
            let display = (name?.isEmpty == false) ? name! : NSFullUserName()
            let entries = Exporter.ladderEntries(from: snap, displayName: display)
            guard !entries.isEmpty else {
                present("No 5h usage to upload yet.")
                return
            }
            let alert = NSAlert()
            alert.messageText = "Upload usage to the Plan Analysis ladder?"
            alert.informativeText = "Only token totals, plan id, and this display name are sent. No prompts, paths, or credentials.\n\nName: \(display)"
            alert.addButton(withTitle: "Upload")
            alert.addButton(withTitle: "Cancel")
            guard alert.runModal() == .alertFirstButtonReturn else { return }
            let base = UserDefaults.standard.string(forKey: "ladderURL")
                ?? "https://plananalysis-ladder.jcyangzh.workers.dev"
            do {
                let result = try await LadderClient(baseURL: URL(string: base)!).upload(entries)
                if let first = result.detailURLs.first {
                    NSWorkspace.shared.open(first)
                }
            } catch {
                present("Upload failed: \(error.localizedDescription)")
            }
        }
    }

    private func present(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Plan Analysis"
        alert.informativeText = message
        alert.runModal()
    }
}

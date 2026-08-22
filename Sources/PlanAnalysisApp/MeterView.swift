import AppKit

final class MeterView: NSView {
    var ratios: [Double] = [0, 0] {
        didSet { needsDisplay = true }
    }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        dirtyRect.fill()
        let bars = max(ratios.count, 1)
        let gap: CGFloat = 2
        let h = max(3, (bounds.height - gap * CGFloat(bars + 1)) / CGFloat(bars))
        for (i, raw) in ratios.enumerated() {
            let y = gap + CGFloat(i) * (h + gap)
            let track = NSRect(x: 1, y: y, width: bounds.width - 2, height: h)
            NSColor.labelColor.withAlphaComponent(0.18).setFill()
            track.fill()
            let width = max(1, track.width * CGFloat(min(1, max(0, raw))))
            let fill = NSRect(x: track.minX, y: track.minY, width: width, height: track.height)
            NSColor.labelColor.setFill()
            fill.fill()
        }
    }
}

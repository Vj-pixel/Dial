import AppKit
import SwiftUI

final class RadialMenuWindowController {

    private var panel: NSPanel?
    private var keyMonitor: Any?
    private let store: AppItemStore

    init(store: AppItemStore) {
        self.store = store
    }

    // MARK: - Show / Hide / Toggle

    func toggle() {
        panel == nil ? show() : hide()
    }

    func show() {
        guard panel == nil, !store.items.isEmpty else { return }

        guard let screen = NSScreen.main else { return }
        let sf = screen.frame

        // Cursor → SwiftUI coords (y flipped, origin top-left)
        let mouse = NSEvent.mouseLocation
        let outerR: CGFloat = 148
        let pad:    CGFloat = outerR + 30
        let cx = (mouse.x - sf.minX).clamped(to: pad...(sf.width - pad))
        let cy = (sf.height - (mouse.y - sf.minY)).clamped(to: pad...(sf.height - pad))
        let center = CGPoint(x: cx, y: cy)

        let p = NSPanel(
            contentRect: sf,
            styleMask:  [.borderless, .nonactivatingPanel],
            backing:    .buffered,
            defer:      false
        )
        p.isOpaque        = false
        p.backgroundColor = .clear
        p.level           = .floating
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.isMovable       = false
        p.ignoresMouseEvents = false
        p.hasShadow       = false

        let view = RadialMenuView(
            items:    store.items,
            center:   center,
            store:    store,
            onSelect: { [weak self] item in self?.select(item) },
            onDismiss: { [weak self] in self?.hide() }
        )

        p.contentView = NSHostingView(rootView: view)
        p.setFrame(sf, display: false)
        p.orderFrontRegardless()
        panel = p

        // Escape key
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { self?.hide(); return nil }
            return event
        }
    }

    func hide() {
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
        panel?.orderOut(nil)
        panel = nil
    }

    // MARK: - Activate / Launch

    private func select(_ item: AppItem) {
        hide()
        let url = item.url
        if let running = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleURL?.standardizedFileURL == url.standardizedFileURL
        }) {
            running.activate(options: [])
        } else {
            let cfg = NSWorkspace.OpenConfiguration()
            cfg.activates = true
            NSWorkspace.shared.openApplication(at: url, configuration: cfg) { _, _ in }
        }
    }
}

// MARK: - Clamp helper

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

import AppKit
import SwiftUI

// Shared navigation state — updated by both mouse hover (view) and arrow keys (key monitor).
final class NavigationState: ObservableObject {
    @Published var hoveredIndex: Int? = nil
    var totalItems: Int = 0

    func navigate(_ delta: Int) {
        guard totalItems > 0 else { return }
        let start = hoveredIndex ?? (delta > 0 ? -1 : 0)
        hoveredIndex = ((start + delta) % totalItems + totalItems) % totalItems
    }

    func reset() { hoveredIndex = nil; totalItems = 0 }
}

final class RadialMenuWindowController {

    private var panel: NSPanel?
    private var keyMonitor: Any?
    private let store: AppItemStore
    private var currentItems: [AppItem] = []
    private let navState = NavigationState()

    init(store: AppItemStore) {
        self.store = store
    }

    // MARK: - Show / Hide

    func show() {
        guard panel == nil else { return }

        if store.showOnlyRunning {
            currentItems = Array(
                NSWorkspace.shared.runningApplications
                    .filter {
                        $0.activationPolicy == .regular &&
                        $0.bundleIdentifier != Bundle.main.bundleIdentifier
                    }
                    .compactMap { app -> AppItem? in
                        guard let url = app.bundleURL else { return nil }
                        let name = app.localizedName
                            ?? url.deletingPathExtension().lastPathComponent
                        return AppItem(name: name, url: url)
                    }
                    .prefix(12)
            )
        } else {
            currentItems = store.items
        }
        guard !currentItems.isEmpty else { return }

        navState.reset()
        navState.totalItems = currentItems.count

        guard let screen = NSScreen.main else { return }
        let sf = screen.frame

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
            items:    currentItems,
            center:   center,
            store:    store,
            onSelect: { [weak self] item in self?.select(item) },
            onDismiss: { [weak self] in self?.hide() },
            navState: navState
        )

        p.contentView = NSHostingView(rootView: view)
        p.setFrame(sf, display: false)
        p.orderFrontRegardless()
        panel = p

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            switch event.keyCode {
            case 53: // Escape
                self.hide()
                return nil
            case 12: // Q — quit hovered app
                if let idx = self.navState.hoveredIndex {
                    let item = self.currentItems[idx]
                    NSWorkspace.shared.runningApplications
                        .first { $0.bundleURL?.standardizedFileURL == item.url.standardizedFileURL }?
                        .terminate()
                    self.hide()
                }
                return nil
            case 123: // ← left arrow
                self.navState.navigate(-1)
                return nil
            case 124: // → right arrow
                self.navState.navigate(1)
                return nil
            default:
                return event
            }
        }
    }

    func hideAndSelectHovered() {
        let item = navState.hoveredIndex.map { currentItems[$0] }
        dismiss()
        if let item { launch(item) }
    }

    func hide() { dismiss() }

    private func dismiss() {
        navState.reset()
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
        panel?.orderOut(nil)
        panel = nil
    }

    // MARK: - Activate / Launch

    private func select(_ item: AppItem) {
        dismiss()
        launch(item)
    }

    private func launch(_ item: AppItem) {
        let url = item.url
        if let running = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleURL?.standardizedFileURL == url.standardizedFileURL
        }) {
            running.activate()
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

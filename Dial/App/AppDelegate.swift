import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private let store = AppItemStore.shared
    private lazy var wheelController = RadialMenuWindowController(store: store)
    private var menuBarController: MenuBarController!
    private var modifierMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        menuBarController = MenuBarController(appDelegate: self)

        // Cmd+Option modifier-only shortcut via flagsChanged.
        // Note: requires Input Monitoring permission on macOS 15 — the system
        // will prompt the user automatically on first use.
        modifierMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags == [.command, .option] {
                self?.wheelController.show()
            } else {
                self?.wheelController.hideAndSelectHovered()
            }
        }
    }

    func openSettings() {
        SettingsWindowController.shared.showWindow(store: store)
    }
}

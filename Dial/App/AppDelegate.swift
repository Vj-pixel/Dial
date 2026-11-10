import AppKit
import KeyboardShortcuts
import ServiceManagement

extension KeyboardShortcuts.Name {
    static let showWheel = Self("showWheel", default: .init(.space, modifiers: .option))
}

final class AppDelegate: NSObject, NSApplicationDelegate {

    private let store = AppItemStore.shared
    private lazy var wheelController = RadialMenuWindowController(store: store)
    private var menuBarController: MenuBarController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        menuBarController = MenuBarController(appDelegate: self)

        KeyboardShortcuts.onKeyDown(for: .showWheel) { [weak self] in
            self?.wheelController.toggle()
        }
    }

    func openSettings() {
        SettingsWindowController.shared.showWindow(store: store)
    }
}

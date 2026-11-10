import AppKit

final class MenuBarController {
    private var statusItem: NSStatusItem!
    private var quitMenu: NSMenu!
    private weak var appDelegate: AppDelegate?

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        setup()
    }

    private func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "dial.max", accessibilityDescription: "Dial")
        button.image?.isTemplate = true
        button.action = #selector(buttonClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.target = self

        // Right-click menu for Quit
        quitMenu = NSMenu()
        quitMenu.addItem(withTitle: "Quit Dial", action: #selector(quit), keyEquivalent: "q").target = self
    }

    @objc private func buttonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            // Show quit menu on right-click
            statusItem.menu = quitMenu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            // Left-click: open settings directly — this is a real user click
            // event that macOS 15 respects for app activation.
            appDelegate?.openSettings()
        }
    }

    @objc private func quit() { NSApp.terminate(nil) }
}

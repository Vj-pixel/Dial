import SwiftUI
import AppKit
import KeyboardShortcuts
import ServiceManagement

// MARK: - Window controller

final class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()

    private init() {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 440),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        win.title = "Dial Settings"
        win.center()
        super.init(window: win)
    }
    required init?(coder: NSCoder) { fatalError() }

    func showWindow(store: AppItemStore) {
        window?.contentView = NSHostingView(rootView: SettingsView(store: store))
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}

// MARK: - Settings view

struct SettingsView: View {
    @ObservedObject var store: AppItemStore
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(store.items) { item in
                    HStack(spacing: 10) {
                        Image(nsImage: item.icon)
                            .resizable()
                            .frame(width: 28, height: 28)
                        Text(item.name)
                        Spacer()
                        Button {
                            store.items.removeAll { $0.id == item.id }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 2)
                }
                .onMove { from, to in store.items.move(fromOffsets: from, toOffset: to) }
            }
            .frame(minHeight: 220)

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Button("Add App…") { addApp() }
                    Spacer()
                    Text("\(store.items.count) apps on the wheel")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                HStack {
                    Text("Shortcut")
                    Spacer()
                    KeyboardShortcuts.Recorder("", name: .showWheel)
                }

                HStack {
                    Toggle("Launch at Login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { _, on in
                            try? on ? SMAppService.mainApp.register()
                                     : SMAppService.mainApp.unregister()
                        }
                    Spacer()
                }
            }
            .padding(16)
        }
    }

    private func addApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            guard !store.items.contains(where: { $0.url == url }) else { continue }
            let name = url.deletingPathExtension().lastPathComponent
            store.items.append(AppItem(name: name, url: url))
        }
    }
}

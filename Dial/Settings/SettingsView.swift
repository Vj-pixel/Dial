import SwiftUI
import AppKit
import ServiceManagement

// MARK: - Window controller

final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private init() {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 580),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        win.title = "Dial Settings"
        win.center()
        super.init(window: win)
        win.delegate = self
    }
    required init?(coder: NSCoder) { fatalError() }

    func showWindow(store: AppItemStore) {
        window?.contentView = NSHostingView(rootView: SettingsView(store: store))
        // This is called from a direct status-item button click, which macOS 15
        // treats as a real user event — activate() works here.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        DispatchQueue.main.async { NSApp.setActivationPolicy(.accessory) }
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
                        .disabled(store.items.count >= 12)
                    Spacer()
                    Text(store.items.count >= 12
                         ? "12 / 12 — max reached"
                         : "\(store.items.count) / 12 apps")
                        .foregroundStyle(store.items.count >= 12 ? .orange : .secondary)
                        .font(.caption)
                }

                HStack {
                    Toggle("Show only running apps", isOn: $store.showOnlyRunning)
                    Spacer()
                }

                HStack {
                    Text("Opacity")
                    Slider(value: $store.wheelOpacity, in: 0.2...1.0)
                        .padding(.horizontal, 8)
                    Text("\(Int(store.wheelOpacity * 100))%")
                        .frame(width: 36, alignment: .trailing)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                HStack {
                    Text("Icon Size")
                    Slider(value: $store.iconSize, in: 20...56, step: 1)
                        .padding(.horizontal, 8)
                    Text("\(Int(store.iconSize))pt")
                        .frame(width: 36, alignment: .trailing)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                HStack {
                    Text("Accent Color")
                    Spacer()
                    ColorPicker("", selection: $store.accentColor)
                        .labelsHidden()
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
        guard store.items.count < 12 else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            guard store.items.count < 12 else { break }
            guard !store.items.contains(where: { $0.url == url }) else { continue }
            let name = url.deletingPathExtension().lastPathComponent
            store.items.append(AppItem(name: name, url: url))
        }
    }
}

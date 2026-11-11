import AppKit
import SwiftUI

struct AppItem: Identifiable, Codable, Hashable {
    var id: UUID = .init()
    var name: String
    var url: URL

    var icon: NSImage { NSWorkspace.shared.icon(forFile: url.path) }
    var bundleID: String? { Bundle(url: url)?.bundleIdentifier }
}

final class AppItemStore: ObservableObject {
    static let shared = AppItemStore()

    @Published var items: [AppItem] = [] { didSet { save() } }
    @Published private(set) var runningBundleIDs: Set<String> = []

    @Published var showOnlyRunning: Bool = UserDefaults.standard.bool(forKey: "dial.showOnlyRunning") {
        didSet { UserDefaults.standard.set(showOnlyRunning, forKey: "dial.showOnlyRunning") }
    }
    @Published var wheelOpacity: Double = {
        let v = UserDefaults.standard.double(forKey: "dial.wheelOpacity")
        return v == 0 ? 0.88 : v
    }() { didSet { UserDefaults.standard.set(wheelOpacity, forKey: "dial.wheelOpacity") } }

    @Published var iconSize: Double = {
        let v = UserDefaults.standard.double(forKey: "dial.iconSize")
        return v == 0 ? 36.0 : v
    }() { didSet { UserDefaults.standard.set(iconSize, forKey: "dial.iconSize") } }

    @Published var accentColor: Color = AppItemStore.loadAccentColor() {
        didSet { AppItemStore.saveAccentColor(accentColor) }
    }

    private static func loadAccentColor() -> Color {
        guard UserDefaults.standard.object(forKey: "dial.accent.r") != nil else { return .white }
        return Color(
            red:   UserDefaults.standard.double(forKey: "dial.accent.r"),
            green: UserDefaults.standard.double(forKey: "dial.accent.g"),
            blue:  UserDefaults.standard.double(forKey: "dial.accent.b")
        )
    }
    private static func saveAccentColor(_ color: Color) {
        if let c = NSColor(color).usingColorSpace(.deviceRGB) {
            UserDefaults.standard.set(Double(c.redComponent),   forKey: "dial.accent.r")
            UserDefaults.standard.set(Double(c.greenComponent), forKey: "dial.accent.g")
            UserDefaults.standard.set(Double(c.blueComponent),  forKey: "dial.accent.b")
        }
    }

    private var observers: [Any] = []
    private static let key = "dial.pinnedApps.v2"

    init() {
        load()
        refreshRunning()
        startObserving()
    }

    func isRunning(_ item: AppItem) -> Bool {
        guard let bid = item.bundleID else { return false }
        return runningBundleIDs.contains(bid)
    }

    private func refreshRunning() {
        let bids = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
        DispatchQueue.main.async { self.runningBundleIDs = bids }
    }

    private func startObserving() {
        let nc = NSWorkspace.shared.notificationCenter
        observers.append(nc.addObserver(forName: NSWorkspace.didLaunchApplicationNotification,
                                        object: nil, queue: .main) { [weak self] note in
            if let bid = (note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.bundleIdentifier {
                self?.runningBundleIDs.insert(bid)
            }
        })
        observers.append(nc.addObserver(forName: NSWorkspace.didTerminateApplicationNotification,
                                        object: nil, queue: .main) { [weak self] note in
            if let bid = (note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.bundleIdentifier {
                self?.runningBundleIDs.remove(bid)
            }
        })
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode([AppItem].self, from: data) {
            items = decoded.filter { FileManager.default.fileExists(atPath: $0.url.path) }
            return
        }
        items = Self.defaultItems()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    static func defaultItems() -> [AppItem] {
        [
            "/Applications/Safari.app",
            "/Applications/Mail.app",
            "/Applications/Messages.app",
            "/Applications/Photos.app",
            "/Applications/Music.app",
            "/System/Applications/Finder.app",
            "/Applications/Notes.app",
            "/Applications/Calendar.app",
        ]
        .filter { FileManager.default.fileExists(atPath: $0) }
        .map { AppItem(name: URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent,
                       url: URL(fileURLWithPath: $0)) }
    }
}

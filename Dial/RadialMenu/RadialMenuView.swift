import SwiftUI
import AppKit

struct RadialMenuView: View {

    let items: [AppItem]
    let center: CGPoint
    let store: AppItemStore
    let onSelect: (AppItem) -> Void
    let onDismiss: () -> Void
    @ObservedObject var navState: NavigationState

    @State private var appeared = false
    // Bundle IDs of running apps that have at least one on-screen window.
    @State private var windowedBundleIDs: Set<String> = []

    private let innerRadius: CGFloat = 58
    private let outerRadius: CGFloat = 148
    private var iconSize: CGFloat { CGFloat(store.iconSize) }

    private var wheelDiameter: CGFloat { (outerRadius + 28) * 2 }
    private var hoveredIndex: Int? { navState.hoveredIndex }

    var body: some View {
        ZStack {
            Color.clear
            wheelLayer
                .position(x: center.x, y: center.y)
                .scaleEffect(appeared ? 1.0 : 0.6)
                .opacity(appeared ? store.wheelOpacity : 0.0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onContinuousHover { phase in
            guard appeared else { return }
            if case .active(let pt) = phase {
                navState.hoveredIndex = sliceIndex(at: pt)
            } else {
                navState.hoveredIndex = nil
            }
        }
        .onTapGesture {
            if let idx = hoveredIndex { onSelect(items[idx]) } else { onDismiss() }
        }
        .onAppear {
            refreshWindowedApps()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) { appeared = true }
        }
    }

    // MARK: - Wheel

    private var wheelLayer: some View {
        ZStack {
            // Ambient drop shadow
            DonutShape(innerRadius: innerRadius, outerRadius: outerRadius)
                .fill(Color.black.opacity(0.25), style: FillStyle(eoFill: true))
                .blur(radius: 22)
                .offset(y: 10)

            // Liquid glass base
            DonutShape(innerRadius: innerRadius, outerRadius: outerRadius)
                .fill(.ultraThinMaterial, style: FillStyle(eoFill: true))
                .shadow(color: .black.opacity(0.14), radius: 28, y: 6)

            // Specular sheen — simulates light hitting glass from top-left
            DonutShape(innerRadius: innerRadius, outerRadius: outerRadius)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.22), .clear, .white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: FillStyle(eoFill: true)
                )

            // Hover highlight — no gap, full sector fill with accent color
            ForEach(Array(items.enumerated()), id: \.element.id) { idx, _ in
                if hoveredIndex == idx {
                    let (s, e) = angles(for: idx)
                    AnnularSector(innerRadius: innerRadius, outerRadius: outerRadius,
                                  startAngle: s, endAngle: e, gap: 0)
                        .fill(store.accentColor.opacity(0.28))
                        .animation(nil, value: hoveredIndex)
                }
            }

            // Outer rim highlight (glass edge)
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 0.75)
                .frame(width: outerRadius * 2, height: outerRadius * 2)

            // Inner rim highlight
            Circle()
                .stroke(Color.white.opacity(0.18), lineWidth: 0.75)
                .frame(width: innerRadius * 2, height: innerRadius * 2)

            // Icons
            ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                iconCell(item: item, index: idx)
            }
        }
        .frame(width: wheelDiameter, height: wheelDiameter)
    }

    @ViewBuilder
    private func iconCell(item: AppItem, index idx: Int) -> some View {
        let (s, e) = angles(for: idx)
        let midRad = (s.radians + e.radians) / 2
        let midR   = (innerRadius + outerRadius) / 2
        let ix = CGFloat(cos(midRad)) * midR
        let iy = CGFloat(sin(midRad)) * midR
        let hovered  = hoveredIndex == idx
        // Gray out if the app is running but has no on-screen windows.
        let noWindows = store.isRunning(item)
            && !(windowedBundleIDs.contains(item.bundleID ?? ""))

        Image(nsImage: item.icon)
            .resizable()
            .interpolation(.high)
            .frame(width: iconSize, height: iconSize)
            .saturation(noWindows ? 0 : 1)
            .opacity(noWindows ? 0.4 : 1.0)
            .scaleEffect(hovered ? 1.18 : 1.0)
            .animation(.spring(response: 0.18, dampingFraction: 0.72), value: hovered)
            .offset(x: ix, y: iy)
    }

    // MARK: - Helpers

    private func refreshWindowedApps() {
        // Use .excludeDesktopElements (not .optionOnScreenOnly) so windows on
        // other spaces / minimized windows are still counted — the app is "open"
        // even if its windows are on a different desktop.
        let pidsWithWindows = Set(
            (CGWindowListCopyWindowInfo([.excludeDesktopElements], kCGNullWindowID)
                as? [[String: Any]] ?? [])
            .filter { ($0[kCGWindowLayer as String] as? Int ?? 1) == 0 }
            .compactMap { $0[kCGWindowOwnerPID as String] as? Int }
        )
        windowedBundleIDs = Set(
            NSWorkspace.shared.runningApplications
                .filter { pidsWithWindows.contains(Int($0.processIdentifier)) }
                .compactMap { $0.bundleIdentifier }
        )
    }

    private func angles(for index: Int) -> (Angle, Angle) {
        let n   = Double(items.count)
        let deg = 360.0 / n
        return (
            .degrees(deg * Double(index) - 90),
            .degrees(deg * Double(index + 1) - 90)
        )
    }

    private func sliceIndex(at point: CGPoint) -> Int? {
        guard !items.isEmpty else { return nil }
        let dx   = point.x - center.x
        let dy   = point.y - center.y
        let dist = sqrt(dx * dx + dy * dy)
        guard dist >= innerRadius, dist <= outerRadius else { return nil }

        var angle = atan2(Double(dy), Double(dx)) + .pi / 2
        if angle < 0 { angle += 2 * .pi }
        let n = Double(items.count)
        return Int(angle / (2 * .pi / n)) % items.count
    }
}

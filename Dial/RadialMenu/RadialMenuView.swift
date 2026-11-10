import SwiftUI
import AppKit

struct RadialMenuView: View {

    let items: [AppItem]
    let center: CGPoint          // cursor in full-screen SwiftUI coords
    let store: AppItemStore
    let onSelect: (AppItem) -> Void
    let onDismiss: () -> Void
    let onHoverChange: (AppItem?) -> Void

    @State private var hoveredIndex: Int? = nil
    @State private var appeared = false

    private let innerRadius: CGFloat = 58
    private let outerRadius: CGFloat = 148
    private let iconSize:    CGFloat = 36

    private var wheelDiameter: CGFloat { (outerRadius + 28) * 2 }

    var body: some View {
        ZStack {
            Color.clear
            wheelLayer
                .position(x: center.x, y: center.y)
                .scaleEffect(appeared ? 1.0 : 0.6)
                .opacity(appeared ? 1.0 : 0.0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onContinuousHover { phase in
            guard appeared else { return }
            hoveredIndex = (phase == .ended) ? nil : {
                if case .active(let pt) = phase { return sliceIndex(at: pt) }
                return nil
            }()
        }
        .onTapGesture {
            if let idx = hoveredIndex { onSelect(items[idx]) } else { onDismiss() }
        }
        .onChange(of: hoveredIndex) { _, newIndex in
            onHoverChange(newIndex.map { items[$0] })
        }
        .onAppear {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) { appeared = true }
        }
    }

    // MARK: - Wheel

    private var wheelLayer: some View {
        ZStack {
            // Frosted-glass donut base
            DonutShape(innerRadius: innerRadius, outerRadius: outerRadius)
                .fill(.ultraThinMaterial, style: FillStyle(eoFill: true))
                .shadow(color: .black.opacity(0.18), radius: 24, y: 6)

            // Slice highlights
            ForEach(Array(items.enumerated()), id: \.element.id) { idx, _ in
                if hoveredIndex == idx {
                    let (s, e) = angles(for: idx)
                    AnnularSector(innerRadius: innerRadius, outerRadius: outerRadius,
                                  startAngle: s, endAngle: e)
                        .fill(.white.opacity(0.22))
                        .animation(nil, value: hoveredIndex)
                }
            }

            // Slice dividers
            ForEach(0..<items.count, id: \.self) { idx in
                let (s, _) = angles(for: idx)
                SliceDivider(angle: s, innerRadius: innerRadius, outerRadius: outerRadius)
                    .stroke(Color.white.opacity(0.18), lineWidth: 0.75)
            }

            // Icons + running dot
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
        let running  = store.isRunning(item)

        VStack(spacing: 4) {
            Image(nsImage: item.icon)
                .resizable()
                .interpolation(.high)
                .frame(width: iconSize, height: iconSize)
                .scaleEffect(hovered ? 1.18 : 1.0)
                .animation(.spring(response: 0.18, dampingFraction: 0.72), value: hovered)

            Circle()
                .fill(Color(red: 0.2, green: 0.85, blue: 0.35))
                .frame(width: 5, height: 5)
                .opacity(running ? 1 : 0)
        }
        .offset(x: ix, y: iy)
    }

    // MARK: - Geometry

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

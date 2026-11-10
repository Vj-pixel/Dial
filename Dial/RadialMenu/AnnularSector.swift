import SwiftUI

// Full donut ring — used as the frosted-glass base.
struct DonutShape: Shape {
    var innerRadius: CGFloat
    var outerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        var p = Path()
        p.addArc(center: c, radius: outerRadius,
                 startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        p.move(to: CGPoint(x: c.x + innerRadius, y: c.y))
        p.addArc(center: c, radius: innerRadius,
                 startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        return p
    }
}

// A single pie-slice ring segment — used for hover highlights.
struct AnnularSector: Shape {
    var innerRadius: CGFloat
    var outerRadius: CGFloat
    var startAngle: Angle
    var endAngle: Angle
    var gap: Double = 1.2   // degrees trimmed from each edge for the divider gap

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let s = Angle.degrees(startAngle.degrees + gap)
        let e = Angle.degrees(endAngle.degrees - gap)
        var p = Path()
        // outer arc clockwise (clockwise: false in SwiftUI's flipped CG system)
        p.addArc(center: c, radius: outerRadius, startAngle: s, endAngle: e, clockwise: false)
        // inner arc back (clockwise: true)
        p.addArc(center: c, radius: innerRadius, startAngle: e, endAngle: s, clockwise: true)
        p.closeSubpath()
        return p
    }
}

// A radial line from inner to outer radius — used as slice dividers.
struct SliceDivider: Shape {
    var angle: Angle
    var innerRadius: CGFloat
    var outerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = angle.radians
        let p1 = CGPoint(x: c.x + CGFloat(cos(r)) * innerRadius,
                         y: c.y + CGFloat(sin(r)) * innerRadius)
        let p2 = CGPoint(x: c.x + CGFloat(cos(r)) * outerRadius,
                         y: c.y + CGFloat(sin(r)) * outerRadius)
        var path = Path()
        path.move(to: p1)
        path.addLine(to: p2)
        return path
    }
}

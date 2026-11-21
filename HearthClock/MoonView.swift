import SwiftUI

/// Moon phase maths. 0 = new moon, 0.5 = full moon, back to 1 = new again.
enum MoonPhase {
    private static let synodicMonth = 29.530588853
    /// New moon on 2000-01-06 18:14 UTC.
    private static let reference = Date(timeIntervalSince1970: 947_182_440)

    static func fraction(for date: Date) -> Double {
        let days = date.timeIntervalSince(reference) / 86_400
        let p = days.truncatingRemainder(dividingBy: synodicMonth) / synodicMonth
        return p < 0 ? p + 1 : p
    }

    static func name(for p: Double) -> String {
        switch p {
        case ..<0.03, 0.97...: "New Moon"
        case ..<0.22: "Waxing Crescent"
        case ..<0.28: "First Quarter"
        case ..<0.47: "Waxing Gibbous"
        case ..<0.53: "Full Moon"
        case ..<0.72: "Waning Gibbous"
        case ..<0.78: "Last Quarter"
        default: "Waning Crescent"
        }
    }
}

/// The lit part of the moon. Waxing phases are lit on the right, waning on the left (northern hemisphere view).
struct MoonLitShape: Shape {
    var phase: Double

    func path(in rect: CGRect) -> Path {
        let r = min(rect.width, rect.height) / 2
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let k = cos(2 * Double.pi * phase)
        let side: Double = phase < 0.5 ? 1 : -1
        let steps = 48

        var path = Path()
        // Outer limb, top to bottom.
        for i in 0...steps {
            let t = Double.pi * Double(i) / Double(steps)
            let pt = CGPoint(x: c.x + CGFloat(side * sin(t)) * r, y: c.y - CGFloat(cos(t)) * r)
            i == 0 ? path.move(to: pt) : path.addLine(to: pt)
        }
        // Terminator, bottom back to top.
        for i in 0...steps {
            let t = Double.pi * Double(steps - i) / Double(steps)
            let pt = CGPoint(x: c.x + CGFloat(side * k * sin(t)) * r, y: c.y - CGFloat(cos(t)) * r)
            path.addLine(to: pt)
        }
        path.closeSubpath()
        return path
    }
}

/// The moon is up from sunset to the next sunrise and crosses the sky from left to right, showing tonight's real phase.
struct MoonView: View {
    let zen: Bool
    let coordinate: Coordinate?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            let sky = SkyClock.state(at: context.date, coordinate: coordinate)
            let visible = !sky.isDay
            // Sunset -> 0, the middle of the night -> 0.5, sunrise -> 1. By day the hidden moon waits off to the side.
            let q = visible ? sky.progress : (sky.progress < 0.5 ? 1.0 : 0.0)
            let phase = MoonPhase.fraction(for: context.date)
            let lit = (1 - cos(2 * Double.pi * phase)) / 2   // 0 new ... 1 full

            GeometryReader { geo in
                ZStack {
                    // Dark side, faintly visible
                    Circle().fill(Color(hex: 0x8FA0C8).opacity(0.16))

                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color(hex: 0xFFFDF2), Color(hex: 0xE9E7DC), Color(hex: 0xC4C6C8)],
                                    center: UnitPoint(x: 0.38, y: 0.34),
                                    startRadius: 0,
                                    endRadius: 48
                                )
                            )
                        Circle().fill(Color(hex: 0xA0A4AC).opacity(0.42)).frame(width: 12, height: 12).offset(x: 11, y: -18)
                        Circle().fill(Color(hex: 0xA0A4AC).opacity(0.38)).frame(width: 16, height: 16).offset(x: -13, y: 6)
                        Circle().fill(Color(hex: 0xA0A4AC).opacity(0.32)).frame(width: 9, height: 9).offset(x: 12, y: 16)
                    }
                    .mask(MoonLitShape(phase: phase))
                }
                .frame(width: 78, height: 78)
                .shadow(color: Color(hex: 0xC8D6FF).opacity(0.1 + 0.3 * lit), radius: 10 + 24 * lit)
                .shadow(color: Color(hex: 0x96AFFF).opacity(0.05 + 0.15 * lit), radius: 80)
                .opacity(visible ? (zen ? 0.7 : 0.92) : 0)
                .position(
                    x: geo.size.width * (0.12 + 0.76 * q),
                    y: geo.size.height * (0.30 - 0.20 * sin(Double.pi * q))
                )
                .accessibilityElement()
                .accessibilityLabel(MoonPhase.name(for: phase))
            }
            .animation(.easeInOut(duration: 1.2), value: visible)
            .animation(.easeInOut(duration: 1.2), value: q)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

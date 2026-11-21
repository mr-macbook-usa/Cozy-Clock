import SwiftUI

/// The two bundled sky photos. The day sky shows from sunrise to sunset (see `SkyClock`).
enum SkyImages {
    static let day = load("day-sky")
    static let night = load("night-sky")

    private static func load(_ name: String) -> UIImage? {
        guard let path = Bundle.main.path(forResource: name, ofType: "jpg") else { return nil }
        return UIImage(contentsOfFile: path)
    }
}

/// Default: the day sky by day and the night sky by night. Otherwise a colour glow or the user's own photo.
/// Zen mode cross-fades to a sage palette and deepens the tint.
struct BackgroundView: View {
    let palette: Palette
    let photo: UIImage?
    let autoSky: Bool
    let zen: Bool
    let coordinate: Coordinate?

    @State private var drift = false

    var body: some View {
        ZStack {
            layer(palette.theme)
            layer(Theme.zen).opacity(zen ? 1 : 0)

            if let photo {
                photoLayer(photo, tint: 0.38)
            } else if autoSky {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    skyLayer(day: SkyClock.state(at: context.date, coordinate: coordinate).isDay)
                }
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 1.4), value: zen)
        .onAppear {
            withAnimation(.easeInOut(duration: 24).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }

    private func skyLayer(day: Bool) -> some View {
        ZStack {
            if let night = SkyImages.night {
                photoLayer(night, tint: 0.10).opacity(day ? 0 : 1)
            }
            if let dayImage = SkyImages.day {
                photoLayer(dayImage, tint: 0.30).opacity(day ? 1 : 0)
            }
        }
        .animation(.easeInOut(duration: 2), value: day)
    }

    private func photoLayer(_ image: UIImage, tint: Double) -> some View {
        Color.clear
            .overlay { Image(uiImage: image).resizable().scaledToFill() }
            .clipped()
            .overlay(Color.black.opacity(zen ? max(tint, 0.5) : tint))
    }

    private func layer(_ t: Theme) -> some View {
        ZStack {
            t.b
            RadialGradient(colors: [t.a, .clear], center: .topLeading, startRadius: 0, endRadius: 560)
            RadialGradient(colors: [t.c, .clear], center: .bottomTrailing, startRadius: 0, endRadius: 600)
            Circle().fill(t.a).frame(width: 420, height: 420).blur(radius: 70).opacity(0.5)
                .offset(x: drift ? 90 : -120, y: drift ? -140 : 60)
            Circle().fill(t.c).frame(width: 380, height: 380).blur(radius: 70).opacity(0.5)
                .offset(x: drift ? -100 : 130, y: drift ? 160 : -40)
        }
    }
}

/// A warm sun that rises at your real sunrise, crosses the sky from left to right, and sets at your real sunset.
struct SunView: View {
    let zen: Bool
    let coordinate: Coordinate?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            let sky = SkyClock.state(at: context.date, coordinate: coordinate)
            let visible = sky.isDay
            // At night the hidden sun waits where it set, then moves to where it will rise.
            let p = visible ? sky.progress : (sky.progress < 0.5 ? 1.0 : 0.0)

            GeometryReader { geo in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: 0xFFF6D6), Color(hex: 0xFFD98A), Color(hex: 0xFFB347)],
                            center: UnitPoint(x: 0.38, y: 0.36),
                            startRadius: 0,
                            endRadius: 52
                        )
                    )
                    .frame(width: 92, height: 92)
                    .shadow(color: Color(hex: 0xFFBE5A).opacity(0.55), radius: 40)
                    .shadow(color: Color(hex: 0xFFAA46).opacity(0.25), radius: 90)
                    .opacity(visible ? (zen ? 0.72 : 0.95) : 0)
                    .position(
                        x: geo.size.width * (0.12 + 0.76 * p),
                        y: geo.size.height * (0.30 - 0.20 * sin(Double.pi * p))
                    )
            }
            .animation(.easeInOut(duration: 1.2), value: visible)
            .animation(.easeInOut(duration: 1.2), value: p)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

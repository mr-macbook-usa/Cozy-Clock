import SwiftUI

/// The big glass slab with the time. In Zen mode the seconds go away, a breathing dot appears,
/// a ring pulses around the border, and the puppy naps on top.
struct ClockCard: View {
    let zen: Bool
    let hour12: Bool
    let showSeconds: Bool
    let accent: Color

    var body: some View {
        TimelineView(.animation(minimumInterval: zen ? 1.0 / 30.0 : 0.25)) { context in
            card(for: context.date)
        }
    }

    @ViewBuilder
    private func card(for date: Date) -> some View {
        let parts = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        let h = parts.hour ?? 0
        let m = parts.minute ?? 0
        let s = parts.second ?? 0
        let shown = hour12 ? (h % 12 == 0 ? 12 : h % 12) : h

        // 8-second breathing cycle: 4 seconds in, 4 seconds out.
        let phase = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 8) / 8
        let breath = 0.5 - 0.5 * cos(2 * Double.pi * phase)

        VStack(spacing: 6) {
            Text(greeting(hour: h, inhale: phase < 0.5))
                .font(.system(.title3, design: .serif).italic().weight(.light))
                .foregroundStyle(accent)

            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text(String(format: hour12 ? "%d:%02d" : "%02d:%02d", shown, m))
                    .font(.system(size: 92, weight: zen ? .ultraLight : .light, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .shadow(color: .black.opacity(0.3), radius: 14, y: 4)

                VStack(alignment: .leading, spacing: 2) {
                    if showSeconds && !zen {
                        Text(String(format: ":%02d", s))
                            .font(.system(size: 30, weight: .light, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.66))
                    }
                    if hour12 {
                        Text(h < 12 ? "AM" : "PM")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .tracking(1.8)
                            .foregroundStyle(accent)
                    }
                }
                .padding(.bottom, 12)
            }

            if zen {
                Circle()
                    .fill(accent)
                    .frame(width: 18, height: 18)
                    .scaleEffect(0.7 + 1.6 * breath)
                    .opacity(0.55 + 0.45 * breath)
                    .shadow(color: accent, radius: 12)
                    .frame(height: 56)
                    .padding(.top, 8)
            } else if showSeconds {
                Capsule()
                    .fill(.white.opacity(0.12))
                    .frame(height: 6)
                    .overlay(alignment: .leading) {
                        GeometryReader { geo in
                            Capsule()
                                .fill(accent)
                                .frame(width: geo.size.width * CGFloat(s) / 60)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 16)
            }
        }
        .padding(.top, 30)
        .padding(.bottom, 26)
        .padding(.horizontal, 22)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: 44))
        .overlay {
            RoundedRectangle(cornerRadius: 44)
                .strokeBorder(accent, lineWidth: 1.5)
                .opacity(zen ? 0.25 + 0.55 * breath : 0)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .topTrailing) {
            if zen {
                PuppyView(breath: breath)
                    .frame(width: 180)
                    .offset(x: -24, y: -102)   // 180 x 0.6 = 108 tall; paws hang 6 pt over the border
                    .allowsHitTesting(false)
                    .transition(.opacity.combined(with: .offset(y: 14)))
            }
        }
    }

    private func greeting(hour: Int, inhale: Bool) -> String {
        if zen { return inhale ? "Breathe in" : "Breathe out" }
        switch hour {
        case 0..<5: return "Burning the midnight oil"
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Time to wind down"
        }
    }
}

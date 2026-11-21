import SwiftUI

/// A sleepy golden retriever puppy, drawn in a 200 x 120 space. Its paws hang over the bottom edge,
/// so place it with its bottom a few points below the top edge of the clock card.
struct PuppyView: View {
    /// 0...1, drives the gentle rise and fall of its breathing.
    var breath: Double = 0

    var body: some View {
        Canvas { context, size in
            var g = context
            let s = size.width / 200
            g.scaleBy(x: s, y: s)
            Self.draw(g)
        }
        .aspectRatio(200.0 / 120.0, contentMode: .fit)
        .scaleEffect(x: 1, y: 1 + 0.035 * breath, anchor: .bottom)
        .accessibilityLabel("A sleepy golden retriever puppy resting on the clock")
    }

    private static func draw(_ ctx: GraphicsContext) {
        func oval(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ color: Color, rotate: Double = 0) {
            let base = Path(ellipseIn: CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2))
            let t = CGAffineTransform(rotationAngle: CGFloat(rotate * .pi / 180))
                .concatenating(CGAffineTransform(translationX: cx, y: cy))
            ctx.fill(base.applying(t), with: .color(color))
        }
        func stroke(_ path: Path, _ width: CGFloat, _ color: Color) {
            ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        }

        let fur = Color(hex: 0xE6AE56)
        let furLight = Color(hex: 0xEFBB63)
        let furHead = Color(hex: 0xEAB55B)
        let ear = Color(hex: 0xC98A36)
        let paw = Color(hex: 0xF4CF86)
        let muzzle = Color(hex: 0xF7DCA4)
        let ink = Color(hex: 0x3A2A24)

        // Tail
        var tail = Path()
        tail.move(to: CGPoint(x: 18, y: 92))
        tail.addCurve(to: CGPoint(x: 12, y: 62), control1: CGPoint(x: 4, y: 88), control2: CGPoint(x: 2, y: 70))
        stroke(tail, 10, Color(hex: 0xD99A3F))

        // Body, haunch, hind paw
        oval(70, 82, 60, 22, fur)
        oval(48, 88, 26, 17, furLight)
        oval(72, 102, 12, 6, paw)

        // Head and floppy ears
        oval(138, 70, 29, 29, furHead)
        oval(112, 72, 10, 21, ear, rotate: 18)
        oval(164, 72, 10, 21, ear, rotate: -18)

        // Muzzle, cheeks, tongue, nose
        oval(138, 82, 16, 11, muzzle)
        oval(120, 78, 4.5, 4.5, Color(hex: 0xFF9A9A).opacity(0.35))
        oval(156, 78, 4.5, 4.5, Color(hex: 0xFF9A9A).opacity(0.35))
        oval(138, 90, 3.6, 4.2, Color(hex: 0xF08A8F))
        oval(138, 75, 6, 4.2, ink)
        oval(136.4, 73.8, 1.8, 1, .white.opacity(0.5))

        // Mouth
        var mouth = Path()
        mouth.move(to: CGPoint(x: 138, y: 79.5))
        mouth.addLine(to: CGPoint(x: 138, y: 83.5))
        mouth.move(to: CGPoint(x: 131.5, y: 83.5))
        mouth.addQuadCurve(to: CGPoint(x: 138, y: 83.5), control: CGPoint(x: 134.7, y: 87.5))
        mouth.addQuadCurve(to: CGPoint(x: 144.5, y: 83.5), control: CGPoint(x: 141.2, y: 87.5))
        stroke(mouth, 1.8, ink)

        // Closed, sleepy eyes
        var eyes = Path()
        eyes.move(to: CGPoint(x: 121, y: 66))
        eyes.addQuadCurve(to: CGPoint(x: 133, y: 66), control: CGPoint(x: 127, y: 72))
        eyes.move(to: CGPoint(x: 143, y: 66))
        eyes.addQuadCurve(to: CGPoint(x: 155, y: 66), control: CGPoint(x: 149, y: 72))
        stroke(eyes, 2.6, ink)

        // Front paws hanging over the edge
        oval(124, 102, 13, 8, paw)
        oval(152, 102, 13, 8, paw)
        var toes = Path()
        for x in [119.0, 124.0, 129.0, 147.0, 152.0, 157.0] {
            let dip: CGFloat = (x == 124 || x == 152) ? 1 : 0
            toes.move(to: CGPoint(x: x, y: 104 + dip))
            toes.addLine(to: CGPoint(x: x, y: 108 + dip))
        }
        stroke(toes, 1.3, Color(hex: 0xD9A24B))
    }
}

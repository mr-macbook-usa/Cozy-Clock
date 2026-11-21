import SwiftUI
import UIKit

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

struct Theme {
    let a: Color
    let b: Color
    let c: Color
    let accent: Color

    /// Soft sage and sand, used while Zen mode is on.
    static let zen = Theme(
        a: Color(hex: 0x4D6B5B),
        b: Color(hex: 0x0E1411),
        c: Color(hex: 0x7A6A48),
        accent: Color(hex: 0xECDCB8)
    )
}

enum Palette: String, CaseIterable, Identifiable {
    case dusk, ember, moss, tide, cocoa

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var theme: Theme {
        switch self {
        case .dusk:  Theme(a: Color(hex: 0x3A2470), b: Color(hex: 0x120F26), c: Color(hex: 0x5A2A5C), accent: Color(hex: 0xFFC08A))
        case .ember: Theme(a: Color(hex: 0x6A2A1F), b: Color(hex: 0x190D10), c: Color(hex: 0x7A3D1C), accent: Color(hex: 0xFFB067))
        case .moss:  Theme(a: Color(hex: 0x1F5440), b: Color(hex: 0x09140F), c: Color(hex: 0x34603F), accent: Color(hex: 0xC6E8A4))
        case .tide:  Theme(a: Color(hex: 0x1D4673), b: Color(hex: 0x08101E), c: Color(hex: 0x1F6068), accent: Color(hex: 0x92DCEA))
        case .cocoa: Theme(a: Color(hex: 0x54382B), b: Color(hex: 0x120C0A), c: Color(hex: 0x6B4630), accent: Color(hex: 0xF4D3A2))
        }
    }
}

enum PhotoStore {
    static var url: URL { URL.documentsDirectory.appending(path: "hearth-background.jpg") }

    static func load() -> UIImage? { UIImage(contentsOfFile: url.path) }

    static func save(_ image: UIImage) {
        try? image.jpegData(compressionQuality: 0.85)?.write(to: url, options: .atomic)
    }

    static func remove() { try? FileManager.default.removeItem(at: url) }
}

extension UIImage {
    func downscaled(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }
        let k = maxDimension / longest
        let newSize = CGSize(width: size.width * k, height: size.height * k)
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

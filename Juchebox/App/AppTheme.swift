import SwiftUI

struct RGBComponents: Sendable, Equatable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    init(r: Double, g: Double, b: Double, a: Double = 1.0) {
        self.red = r
        self.green = g
        self.blue = b
        self.alpha = a
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    /// WCAG 2.1 relative luminance
    var relativeLuminance: Double {
        func channelLuminance(_ c: Double) -> Double {
            c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        let r = channelLuminance(red)
        let g = channelLuminance(green)
        let b = channelLuminance(blue)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    func contrastRatio(to other: RGBComponents) -> Double {
        let l1 = self.relativeLuminance
        let l2 = other.relativeLuminance
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }
}

enum AppTheme {
    static let backgroundRGB = RGBComponents(r: 0.04, g: 0.04, b: 0.04)
    static let surfaceRGB = RGBComponents(r: 0.10, g: 0.05, b: 0.05)
    static let elevatedSurfaceRGB = RGBComponents(r: 0.16, g: 0.07, b: 0.08)
    static let primaryTextRGB = RGBComponents(r: 0.96, g: 0.95, b: 0.92)
    static let secondaryTextRGB = RGBComponents(r: 0.83, g: 0.66, b: 0.26)
    static let mutedTextRGB = RGBComponents(r: 0.60, g: 0.50, b: 0.50)
    static let accentRGB = RGBComponents(r: 0.804, g: 0.125, b: 0.153)
    static let accentOnDarkRGB = RGBComponents(r: 0.93, g: 0.30, b: 0.32)
    static let warningRGB = RGBComponents(r: 0.831, g: 0.659, b: 0.263)
    static let destructiveRGB = RGBComponents(r: 0.70, g: 0.10, b: 0.10)

    static let background = backgroundRGB.color
    static let surface = surfaceRGB.color
    static let elevatedSurface = elevatedSurfaceRGB.color
    static let hairline = secondaryTextRGB.color.opacity(0.2)
    static let primaryText = primaryTextRGB.color
    static let secondaryText = secondaryTextRGB.color
    static let mutedText = mutedTextRGB.color
    static let accent = accentRGB.color
    static let accentOnDark = accentOnDarkRGB.color
    static let warning = warningRGB.color
    static let destructive = destructiveRGB.color
}

enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

enum AppRadius {
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
}

enum AppMotion {
    static let fast: TimeInterval = 0.15
    static let defaultDuration: TimeInterval = 0.25
}


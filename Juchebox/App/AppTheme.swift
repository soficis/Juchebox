import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.04, green: 0.04, blue: 0.04)
    static let surface = Color(red: 0.10, green: 0.05, blue: 0.05)
    static let elevatedSurface = Color(red: 0.16, green: 0.07, blue: 0.08)
    static let hairline = Color(red: 0.83, green: 0.66, blue: 0.26).opacity(0.2)
    static let primaryText = Color(red: 0.96, green: 0.95, blue: 0.92)
    static let secondaryText = Color(red: 0.83, green: 0.66, blue: 0.26)
    static let mutedText = Color(red: 0.6, green: 0.5, blue: 0.5)
    static let accent = Color(red: 0.804, green: 0.125, blue: 0.153)
    static let warning = Color(red: 0.831, green: 0.659, blue: 0.263)
    static let destructive = Color(red: 0.7, green: 0.1, blue: 0.1)
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


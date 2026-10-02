import XCTest
@testable import Juchebox

final class AppThemeContrastTests: XCTestCase {
    func testAccentOnDarkLuminanceContrastVsBackgroundExceedsWCAGAA() {
        let contrast = AppTheme.accentOnDarkRGB.contrastRatio(to: AppTheme.backgroundRGB)
        XCTAssertGreaterThanOrEqual(
            contrast, 4.5,
            "accentOnDark (\(contrast):1) must meet or exceed WCAG AA 4.5:1 on background"
        )
    }

    func testAccentOnDarkLuminanceContrastVsElevatedSurfaceExceedsWCAGControl() {
        let contrast = AppTheme.accentOnDarkRGB.contrastRatio(to: AppTheme.elevatedSurfaceRGB)
        XCTAssertGreaterThanOrEqual(
            contrast, 3.0,
            "accentOnDark (\(contrast):1) must meet or exceed WCAG 3.0:1 on elevatedSurface"
        )
    }

    func testMutedTextContrastVsBackgroundExceedsWCAGAA() {
        let contrast = AppTheme.mutedTextRGB.contrastRatio(to: AppTheme.backgroundRGB)
        XCTAssertGreaterThanOrEqual(
            contrast, 4.5,
            "mutedText (\(contrast):1) must meet or exceed WCAG AA 4.5:1 on background"
        )
    }

    func testSecondaryTextContrastVsBackgroundExceedsWCAGAA() {
        let contrast = AppTheme.secondaryTextRGB.contrastRatio(to: AppTheme.backgroundRGB)
        XCTAssertGreaterThanOrEqual(
            contrast, 4.5,
            "secondaryText (\(contrast):1) must meet or exceed WCAG AA 4.5:1 on background"
        )
    }
}

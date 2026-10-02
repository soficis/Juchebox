import XCTest
import UIKit
@testable import Juchebox

final class TabBarSymbolsTests: XCTestCase {
    func testTabBarSymbolsExistInSystem() {
        let symbols = [
            "house",
            "house.fill",
            "magnifyingglass",
            "music.note.list",
            "music.note",
            "play.circle.fill"
        ]
        for name in symbols {
            XCTAssertNotNil(
                UIImage(systemName: name),
                "SF Symbol '\(name)' must exist in system"
            )
        }
    }
}

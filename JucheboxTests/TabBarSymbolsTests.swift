import XCTest
import UIKit
@testable import Juchebox

final class TabBarSymbolsTests: XCTestCase {
    func testTabBarSymbolsExistInSystem() {
        // Will be expanded in Task 5
        let symbols = ["magnifyingglass"]
        for name in symbols {
            XCTAssertNotNil(UIImage(systemName: name), "Symbol \(name) must exist in SF Symbols")
        }
    }
}

import XCTest
@testable import ColorMeterKit

final class ColorMeterKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ColorMeterKit().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

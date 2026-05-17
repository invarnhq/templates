import XCTest
@testable import IosSpmDemo

final class IosSpmDemoTests: XCTestCase {
    func testGreeterReturnsExpectedString() {
        XCTAssertEqual(Greeter.greet("Invarn"), "Hello, Invarn!")
    }

    func testGreeterHandlesEmptyName() {
        XCTAssertEqual(Greeter.greet(""), "Hello, !")
    }
}

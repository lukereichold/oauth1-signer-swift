import XCTest
@testable import MastercardOAuth1Signer

final class MastercardOAuth1SignerTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(MastercardOAuth1Signer().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

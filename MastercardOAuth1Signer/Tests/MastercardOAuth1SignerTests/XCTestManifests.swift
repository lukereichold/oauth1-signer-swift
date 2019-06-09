import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(MastercardOAuth1SignerTests.allTests),
    ]
}
#endif

import XCTest
@testable import CLIStatusApp

final class CLIStatusAppTests: XCTestCase {
    func testVersionParsing() {
        let version = VersionInfo(string: "1.2.3")
        XCTAssertNotNil(version)
        XCTAssertEqual(version?.display, "1.2.3")
    }
}

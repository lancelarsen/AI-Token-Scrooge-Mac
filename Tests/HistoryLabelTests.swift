import XCTest
@testable import AITokenScrooge

final class HistoryLabelTests: XCTestCase {
    func testCrowdedLabelsKeepOrderAndStayInsidePlot() {
        let positions = HistoryLabelLayout.positions([100, 100, 100, 101], top: 0, bottom: 100)
        XCTAssertEqual(positions, [25, 50, 75, 100])
        XCTAssertEqual(HistoryLabelLayout.positions([], top: 0, bottom: 10), [])
        XCTAssertEqual(HistoryLabelLayout.positions([4, 4, 4], top: 0, bottom: 10), [0, 5, 10])
    }
}

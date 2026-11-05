import XCTest
@testable import AITokenScrooge

final class HorizonPerformanceTests: XCTestCase {
    func testNavigatorDragPreservesGrabOffsetAndClamps() {
        let now = Date(timeIntervalSince1970: 1793793600)
        var viewport = HorizonViewport(now: now, furthestFuture: now.addingTimeInterval(30 * 86400),
                                       zone: TimeZone(secondsFromGMT: 0)!, width: 800)
        let start = viewport.scrollOffset
        viewport.dragOverview(startOffset: start, translation: 0, trackWidth: 1000)
        XCTAssertEqual(viewport.scrollOffset, start)
        viewport.dragOverview(startOffset: start, translation: 20, trackWidth: 1000)
        XCTAssertEqual(viewport.scrollOffset, start + viewport.contentWidth * 0.02, accuracy: 0.00001)
        viewport.dragOverview(startOffset: start, translation: -10000, trackWidth: 1000)
        XCTAssertEqual(viewport.scrollOffset, 0)
        viewport.dragOverview(startOffset: start, translation: 10000, trackWidth: 1000)
        XCTAssertEqual(viewport.scrollOffset, viewport.maximumScrollOffset)
        viewport.dragOverview(startOffset: start, translation: .nan, trackWidth: 1000)
        viewport.dragOverview(startOffset: start, translation: 20, trackWidth: 0)
        XCTAssertEqual(viewport.scrollOffset, viewport.maximumScrollOffset)
    }

    func testWheelMotionConservesDistanceAndReversesImmediately() {
        var motion = HorizonWheelMotion()
        motion.enqueue(80)
        let first = motion.step(seconds: 1.0 / 120)
        XCTAssertGreaterThan(first, 0)
        XCTAssertLessThan(first, 80)
        var total = first
        for _ in 0..<120 { total += motion.step(seconds: 1.0 / 120) }
        XCTAssertEqual(total, 80, accuracy: 0.0001)
        XCTAssertEqual(motion.remaining, 0)
        motion.enqueue(100)
        _ = motion.step(seconds: 1.0 / 60)
        motion.enqueue(-20)
        XCTAssertLessThan(motion.step(seconds: 1.0 / 120), 0)
        motion.cancel()
        XCTAssertEqual(motion.step(seconds: 1.0 / 60), 0)
        motion.enqueue(.infinity)
        XCTAssertEqual(motion.remaining, 0)
    }
    func testBoundedHistorySearchPreservesInclusiveTiesWithoutFullScan() {
        let points = (0..<50_000).map { index in
            HistoryPoint(at: Date(timeIntervalSince1970: Double(index / 2)), remaining: 50,
                         windowID: "weekly", startsSegment: false, estimated: false, replenishedFrom: nil)
        }
        var projections = 0
        let selected = UsageHistory.pointsWithin(points, left: 12_000, right: 12_002) {
            projections += 1
            return $0.timeIntervalSince1970
        }
        XCTAssertEqual(Array(selected), Array(points[24_000..<24_006]))
        XCTAssertLessThan(projections, 40)
        XCTAssertTrue(UsageHistory.pointsWithin(points, left: -2, right: -1, project: { $0.timeIntervalSince1970 }).isEmpty)
        XCTAssertTrue(UsageHistory.pointsWithin(points, left: 2, right: 1, project: { $0.timeIntervalSince1970 }).isEmpty)
        XCTAssertEqual(UsageHistory.pointsWithin(points, left: 24_999, right: 30_000, project: { $0.timeIntervalSince1970 }).count, 2)
    }

    func testShortHistorySurvivesDisabledViewportAndBoundsNavigation() {
        let now = Date(timeIntervalSince1970: 1793732400)
        let demo = DemoData.make(now: now)
        let cutoff = now.addingTimeInterval(-3600)
        let runs = demo.1.filter { $0.firstObservedAt >= cutoff }
        let first = runs.map(\.firstObservedAt).min()!
        var viewport = HorizonViewport(now: now, furthestFuture: now.addingTimeInterval(7 * 86400), zone: TimeZone(secondsFromGMT: 0)!, width: 700, historyEnabled: false)
        let disabled = HorizonPresentation(accounts: demo.0.accounts, runs: runs, viewport: viewport, now: now)
        let earliest = disabled.series.flatMap(\.points).map(\.at).min()!
        XCTAssertEqual(earliest, first)
        viewport.update(now: now, furthestFuture: now.addingTimeInterval(7 * 86400), zone: viewport.zone, width: 700, historyEnabled: true, earliestHistory: earliest)
        viewport.scroll(to: 0)
        XCTAssertEqual(viewport.visibleStart.timeIntervalSince1970, first.timeIntervalSince1970, accuracy: 0.001)
        let enabled = HorizonPresentation(accounts: demo.0.accounts, runs: runs, viewport: viewport, now: now)
        XCTAssertEqual(enabled.series.flatMap(\.points), disabled.series.flatMap(\.points))
    }

    func testPreparedHistoryMatchesProjectionAcrossScrolling() {
        let now = Date(timeIntervalSince1970: 1793732400)
        let demo = DemoData.make(now: now)
        var viewport = HorizonViewport(now: now, furthestFuture: now.addingTimeInterval(7 * 86400), zone: TimeZone(identifier: "America/Chicago")!, width: 1200)
        let presentation = HorizonPresentation(accounts: demo.0.accounts, runs: demo.1, viewport: viewport, now: now)
        XCTAssertFalse(presentation.positions.isEmpty)
        viewport.scroll(to: 0)
        for (date, position) in presentation.positions { XCTAssertEqual(position, viewport.position(at: date), accuracy: 0.001) }
        let points = presentation.series.flatMap(\.points)
        let clock = ContinuousClock()
        var originalSum = 0.0, preparedSum = 0.0
        let original = clock.measure { for _ in 0..<20 { for point in points { originalSum += viewport.position(at: point.at) } } }
        let prepared = clock.measure { for _ in 0..<20 { for point in points { preparedSum += presentation.positions[point.at]! } } }
        XCTAssertEqual(originalSum, preparedSum, accuracy: 0.001)
        print("History projection benchmark: \(points.count) points × 20; calendar=\(original), prepared=\(prepared)")
    }
}

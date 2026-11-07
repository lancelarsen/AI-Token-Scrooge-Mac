import XCTest
@testable import AITokenScrooge

final class HorizonPerformanceTests: XCTestCase {
    func testPreparedDayGeometryPreservesCalendarProjectionAndRejectsChangedGeometry() throws {
        let cases = [("2026-11-07T16:00:00Z", "America/Chicago", 23),
                     ("2026-03-10T16:00:00Z", "America/Chicago", 23),
                     ("2018-11-11T16:00:00Z", "America/Sao_Paulo", 23),
                     ("2012-01-02T16:00:00Z", "Pacific/Apia", 24),
                     ("2026-11-07T16:00:00Z", "UTC", 23)]
        for (text, zoneID, expectedCount) in cases {
            let now = try XCTUnwrap(ISO8601DateFormatter().date(from: text))
            var viewport = HorizonViewport(now: now, furthestFuture: now.addingTimeInterval(14 * 86400),
                                           zone: TimeZone(identifier: zoneID)!, width: 700)
            let geometry = HorizonDayGeometry(viewport: viewport)
            XCTAssertTrue(geometry.matches(viewport))
            var calendar = Calendar(identifier: .gregorian); calendar.timeZone = viewport.zone
            XCTAssertEqual(geometry.days.first, calendar.startOfDay(for: viewport.date(at: 0)))
            XCTAssertEqual(geometry.days.count, expectedCount)
            for day in geometry.days {
                XCTAssertEqual(geometry.positions[day], viewport.position(at: day))
                XCTAssertEqual(geometry.anchors[day], viewport.dayAnchor(day))
            }
            viewport.scroll(to: 0)
            XCTAssertTrue(geometry.matches(viewport), "Panning must reuse day geometry")
            viewport.scroll(to: viewport.maximumScrollOffset)
            XCTAssertTrue(geometry.matches(viewport))
            var resizedViewport = viewport
            resizedViewport.update(now: now, furthestFuture: viewport.lastEventAt,
                                   zone: viewport.zone, width: 2000, historyEnabled: true)
            XCTAssertFalse(geometry.matches(resizedViewport), "Scale changes must invalidate the cache")
            var extendedViewport = viewport
            extendedViewport.update(now: now, furthestFuture: now.addingTimeInterval(30 * 86400),
                                    zone: viewport.zone, width: 700, historyEnabled: true)
            XCTAssertFalse(geometry.matches(extendedViewport), "Extent changes must invalidate the cache")
            viewport.update(now: now, furthestFuture: now.addingTimeInterval(30 * 86400),
                            zone: viewport.zone, width: 1100, historyEnabled: false)
            XCTAssertFalse(geometry.matches(viewport), "Changed extent/scale must invalidate the cache")
            let resized = HorizonDayGeometry(viewport: viewport)
            XCTAssertTrue(resized.matches(viewport))
            viewport.update(now: now, furthestFuture: viewport.lastEventAt,
                            zone: TimeZone(secondsFromGMT: 19800)!, width: 1100, historyEnabled: false)
            XCTAssertFalse(resized.matches(viewport), "Time-zone changes must invalidate the cache")
        }
    }

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
    func testWheelDistanceIsIndependentOfDisplayCadence() {
        for cadence in [30.0, 60, 120, 144] {
            var motion = HorizonWheelMotion()
            motion.enqueue(240)
            var distance = 0.0
            for _ in 0..<Int(cadence * 2) {
                distance += motion.step(seconds: 1 / cadence)
            }
            XCTAssertEqual(distance, 240, accuracy: 0.0001, "Cadence: \(cadence)")
            XCTAssertEqual(motion.remaining, 0)
        }
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

    func testPreparedFutureEventsRetainClockCutoffsIdentityAndDayBuckets() throws {
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-11-01T07:30:00Z"))
        var state = DemoData.make(now: now).0
        for zone in ["America/Chicago", "America/Los_Angeles", "Asia/Tokyo"] {
            state.settings.timeZoneID = zone
            var calendar = Calendar(identifier: .gregorian); calendar.timeZone = state.settings.zone
            let prepared = HorizonFuturePresentation(state: state)
            for hour in [0.0, 2, 4, 24, 96, 240] {
                let clock = now.addingTimeInterval(hour * 3600)
                let expected = HorizonEvent.events(state: state, now: clock)
                XCTAssertEqual(prepared.events(after: clock).map(\.id), expected.map(\.id))
                XCTAssertEqual(prepared.events(after: clock).map(\.date), expected.map(\.date))
                let groups = Dictionary(grouping: expected) { calendar.startOfDay(for: $0.date) }
                XCTAssertEqual(prepared.maximumRows(after: clock), groups.values.map(\.count).max() ?? 0)
                for (day, values) in groups {
                    XCTAssertEqual(prepared.events(on: day, after: clock).map(\.id), values.map(\.id))
                }
            }
        }
        state.accounts[0].subject = "changed-identity"
        state.accounts[1].enabled = false
        state.settings.hiddenHistoryAccounts = [state.accounts[2].id]
        let prepared = HorizonFuturePresentation(state: state)
        XCTAssertEqual(prepared.events(after: now).map(\.id), HorizonEvent.events(state: state, now: now).map(\.id))
        XCTAssertTrue(prepared.events(after: now).allSatisfy { $0.account.id == state.accounts[3].id })
        let cutoff = try XCTUnwrap(prepared.events(after: now).first?.date)
        XCTAssertFalse(prepared.events(after: cutoff).contains { $0.date == cutoff },
            "Passing time must expire a cached event without a new provider snapshot")
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

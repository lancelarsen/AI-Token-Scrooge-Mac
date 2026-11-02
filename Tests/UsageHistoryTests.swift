import XCTest
@testable import AITokenScrooge

final class UsageHistoryTests: XCTestCase {
    func testGapHoverIsExplicitEstimateAndNeverBridgesNewSegment() {
        let now = Date(timeIntervalSince1970: 1800000000)
        let viewport = HorizonViewport(now: now, furthestFuture: nil, zone: TimeZone(secondsFromGMT: 0)!, width: 700)
        let before = HistoryPoint(at: now.addingTimeInterval(-7200), remaining: 80, windowID: "weekly", startsSegment: true, estimated: false)
        var after = HistoryPoint(at: now, remaining: 40, windowID: "weekly", startsSegment: false, estimated: true)
        let x = (viewport.position(at: before.at) + viewport.position(at: after.at)) / 2
        let estimate = UsageHistory.estimatedPoint(points: [before, after], x: x, y: 215, viewport: viewport)
        XCTAssertEqual(estimate?.remaining, 60)
        XCTAssertEqual(estimate?.at, now.addingTimeInterval(-3600))
        XCTAssertEqual(estimate?.estimated, true)
        XCTAssertNil(UsageHistory.estimatedPoint(points: [before, after], x: x, y: 95, viewport: viewport))
        after.startsSegment = true
        XCTAssertNil(UsageHistory.estimatedPoint(points: [before, after], x: x, y: 215, viewport: viewport))
    }
    func testDemoHistoryEndsAtCurrentUsageAndIncludesReportingGap() {
        let now = Date(timeIntervalSince1970: 1800000000)
        let (state, runs) = DemoData.make(now: now)
        for account in state.accounts {
            let current = state.snapshots[account.id]!
            let window = UsageHistory.selectWindow(provider: account.provider, windows: current.windows).window!
            let history = runs.filter { $0.snapshot.accountID == account.id }
            XCTAssertEqual(history.last?.snapshot.observedAt, now)
            XCTAssertEqual(history.last?.snapshot.windows.first?.remainingPercent, window.remainingPercent)
            let series = UsageHistory.build(account: account, runs: history, from: now.addingTimeInterval(-8 * 86400), through: now)
            XCTAssertEqual(series.points.last?.remaining, window.remainingPercent)
            if account.provider == .claude { XCTAssertTrue(series.points.contains(where: \.estimated)) }
        }
    }
    func testWeeklySelectionPrefersCanonicalBucketAndRejectsAmbiguity() {
        let session = QuotaWindow(id: "codex/primary", name: "Session", unit: .percent, used: 20, durationMinutes: 300)
        let weekly = QuotaWindow(id: "codex/secondary", name: "Weekly", unit: .percent, used: 70, durationMinutes: 10080)
        var other = weekly; other.id = "other/weekly"
        XCTAssertEqual(UsageHistory.selectWindow(provider: .codex, windows: [session, weekly, other]).window?.id, weekly.id)
        var third = other; third.id = "third/weekly"
        XCTAssertTrue(UsageHistory.selectWindow(provider: .codex, windows: [other, third]).ambiguous)
        XCTAssertNil(UsageHistory.selectWindow(provider: .codex, windows: [session]).window)
    }
    func testMeasuredReplenishmentAndEstimatedGapRemainDistinct() {
        let account = ProviderAccount(provider: .codex, nickname: "Test", subject: "s", scope: "w")
        let now = Date(timeIntervalSince1970: 1800000000)
        func run(_ seconds: Double, _ used: Decimal) -> HistoryRun {
            let snapshot = QuotaSnapshot(accountID: account.id, subject: "s", scope: "w", observedAt: now.addingTimeInterval(seconds),
                windows: [QuotaWindow(id: "codex/secondary", name: "Weekly", unit: .percent, used: used, durationMinutes: 10080)])
            return HistoryRun(snapshot: snapshot, lastObservedAt: snapshot.observedAt, pollingMinutes: 2)
        }
        let series = UsageHistory.build(account: account, runs: [run(0, 80), run(120, 10), run(3600, 50)], from: now, through: now.addingTimeInterval(3600))
        XCTAssertEqual(series.points.count, 3)
        XCTAssertEqual(series.points[1].replenishedFrom, 20)
        XCTAssertFalse(series.points[1].estimated)
        XCTAssertTrue(series.points[2].estimated)
        XCTAssertNil(series.points[2].replenishedFrom)
    }
    func testPixelReductionRetainsExtremesAndGapEdges() {
        let now = Date(timeIntervalSince1970: 1800000000)
        let points: [HistoryPoint] = (0..<100).map { index in
            let remaining: Decimal = index == 40 ? 0 : index == 60 ? 100 : 50
            return HistoryPoint(at: now.addingTimeInterval(Double(index)), remaining: remaining,
                         windowID: "q", startsSegment: index == 0, estimated: index == 80, replenishedFrom: nil)
        }
        let reduced = UsageHistory.reduce(points, project: { $0.timeIntervalSince(now) / 100 }, minX: 0, maxX: 1)
        XCTAssertLessThan(reduced.count, points.count)
        for index in [0, 40, 60, 79, 80, 81, 99] { XCTAssertTrue(reduced.contains(points[index])) }
    }
}

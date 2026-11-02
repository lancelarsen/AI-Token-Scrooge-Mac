import XCTest
@testable import AITokenScrooge

final class UsageHistoryTests: XCTestCase {
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

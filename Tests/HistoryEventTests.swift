import XCTest
@testable import AITokenScrooge

final class HistoryEventTests: XCTestCase {
    func testFutureDayIconsRespectCurrentTimeBoundaryOnlyInHistoryMode() {
        let day = Date(timeIntervalSince1970: Double(Int(1_800_000_000) / 86_400 * 86_400))
        let zone = TimeZone(secondsFromGMT: 0)!
        let morning = HorizonViewport(now: day.addingTimeInterval(9 * 3600), furthestFuture: nil, zone: zone, width: 700)
        let evening = HorizonViewport(now: day.addingTimeInterval(23 * 3600), furthestFuture: nil, zone: zone, width: 700)
        XCTAssertTrue(morning.showsFutureEvents(on: day))
        XCTAssertFalse(evening.showsFutureEvents(on: day))
        let withoutHistory = HorizonViewport(now: day.addingTimeInterval(23 * 3600), furthestFuture: nil, zone: zone, width: 700, historyEnabled: false)
        XCTAssertTrue(withoutHistory.showsFutureEvents(on: day))
        XCTAssertFalse(morning.showsFutureEvents(on: day.addingTimeInterval(30 * 86400)))
    }
    func testHistoricalMarkersGroupExactTimesAndKeepNearbyEventsInSeparateLanes() {
        let now = Date(timeIntervalSince1970: 1800000000)
        var viewport = HorizonViewport(now: now, furthestFuture: nil, zone: TimeZone(secondsFromGMT: 0)!, width: 700)
        viewport.scroll(to: 0)
        let account = ProviderAccount(provider: .codex, nickname: "Test", subject: "s", scope: "w")
        let at = now.addingTimeInterval(-86400)
        func event(_ id: String, _ date: Date, expiration: Bool = false) -> HorizonEvent {
            HorizonEvent(id: id, account: account, date: date, expiration: expiration, title: "Event", reportedAt: at)
        }
        let markers = HistoricalEventMarker.layout(events: [event("b", at), event("a", at), event("c", at.addingTimeInterval(60)), event("d", at, expiration: true), event("future", now.addingTimeInterval(60))], viewport: viewport, now: now)
        XCTAssertEqual(markers.count, 3)
        XCTAssertEqual(markers[0].events.map(\.id), ["a", "b"])
        XCTAssertEqual(markers.map(\.lane), [0, 1, 2])
        XCTAssertEqual(markers[0].x, viewport.position(at: at))
        XCTAssertEqual(markers[2].x, viewport.position(at: at.addingTimeInterval(60)))
        XCTAssertTrue(markers[1].expiration)
    }
    func testFutureEventsPreserveQuotaIdentityForDetails() throws {
        let now = Date(timeIntervalSince1970: 1800000000)
        let (state, _) = DemoData.make(now: now)
        let events = HorizonEvent.events(state: state, now: now)
        XCTAssertTrue(events.contains { $0.expiration })
        XCTAssertTrue(events.contains { !$0.expiration })
        for event in events {
            if event.expiration {
                XCTAssertNil(event.windowID)
            } else {
                let windowID = try XCTUnwrap(event.windowID)
                let snapshot = try XCTUnwrap(state.snapshots[event.account.id])
                let window = try XCTUnwrap(snapshot.windows.first { $0.id == windowID })
                XCTAssertEqual(window.resetsAt, event.date)
                XCTAssertEqual(window.name, event.title)
            }
        }
    }
    func testPausedHiddenAndMismatchedAccountsDoNotProduceFutureEvents() {
        let now = Date(timeIntervalSince1970: 1800000000)
        let (demo, _) = DemoData.make(now: now)
        var state = demo
        let account = state.accounts[0]
        XCTAssertFalse(HorizonEvent.events(state: state, now: now).filter { $0.account.id == account.id }.isEmpty)
        state.accounts[0].enabled = false
        XCTAssertFalse(HorizonEvent.events(state: state, now: now).contains { $0.account.id == account.id })
        XCTAssertNotNil(state.snapshots[account.id])
        state.accounts[0].enabled = true
        state.settings.hiddenHistoryAccounts.insert(account.id)
        XCTAssertFalse(HorizonEvent.events(state: state, now: now).contains { $0.account.id == account.id })
        state.settings.hiddenHistoryAccounts.remove(account.id)
        state.snapshots[account.id]?.subject = "different-subject"
        XCTAssertFalse(HorizonEvent.events(state: state, now: now).contains { $0.account.id == account.id })
    }
    func testEarlyRevisionReplacesScheduleButDueRevisionRetainsIt() {
        let account = ProviderAccount(provider: .codex, nickname: "A", subject: "s", scope: "w")
        let start = Date(timeIntervalSince1970: 1800000000)
        func run(_ observed: Double, reset: Double) -> HistoryRun {
            let snapshot = QuotaSnapshot(accountID: account.id, subject: "s", scope: "w", observedAt: start.addingTimeInterval(observed), windows: [QuotaWindow(id: "codex/secondary", name: "Weekly", unit: .percent, used: 20, resetsAt: start.addingTimeInterval(reset), durationMinutes: 10080)])
            return HistoryRun(snapshot: snapshot, lastObservedAt: snapshot.observedAt, pollingMinutes: 2)
        }
        let early = UsageHistory.events(account: account, runs: [run(0, reset: 100), run(50, reset: 200)], from: start, through: start.addingTimeInterval(300))
        XCTAssertEqual(early.map(\.date), [start.addingTimeInterval(200)])
        let due = UsageHistory.events(account: account, runs: [run(0, reset: 100), run(120, reset: 200)], from: start, through: start.addingTimeInterval(300))
        XCTAssertEqual(due.map(\.date), [start.addingTimeInterval(100), start.addingTimeInterval(200)])
    }
    func testCreditUsedBeforeExpiryRemovesPredictedExpiration() {
        let account = ProviderAccount(provider: .codex, nickname: "A", subject: "s", scope: "w")
        let start = Date(timeIntervalSince1970: 1800000000)
        var snapshot = QuotaSnapshot(accountID: account.id, subject: "s", scope: "w", observedAt: start, windows: [], reserve: ResetReserve(availableCount: 1, credits: [ResetCredit(id: "credit", status: "available", expiresAt: start.addingTimeInterval(200))]))
        let initial = HistoryRun(snapshot: snapshot, lastObservedAt: start, pollingMinutes: 2)
        snapshot.observedAt = start.addingTimeInterval(100); snapshot.reserve?.credits?[0].status = "used"
        let used = HistoryRun(snapshot: snapshot, lastObservedAt: snapshot.observedAt, pollingMinutes: 2)
        XCTAssertEqual(UsageHistory.events(account: account, runs: [initial], from: start, through: start.addingTimeInterval(300)).count, 1)
        XCTAssertTrue(UsageHistory.events(account: account, runs: [initial, used], from: start, through: start.addingTimeInterval(300)).isEmpty)
    }
}

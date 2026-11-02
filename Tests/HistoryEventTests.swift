import XCTest
@testable import AITokenScrooge

final class HistoryEventTests: XCTestCase {
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

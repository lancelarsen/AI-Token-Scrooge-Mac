import XCTest
@testable import AITokenScrooge

final class MonitoringTests: XCTestCase {
    func testManualRefreshHonorsProviderThrottle() {
        let now = Date(timeIntervalSince1970: 1800000000)
        var schedule = RefreshSchedule()
        schedule.failed("a", now: now, retryAt: now.addingTimeInterval(300))
        XCTAssertFalse(schedule.shouldRefresh("a", now: now, force: true))
        XCTAssertTrue(schedule.shouldRefresh("a", now: now.addingTimeInterval(300), force: true))
    }
    func testSuccessSchedulesEarlierResetAndFailureBacksOff() {
        let now = Date(timeIntervalSince1970: 1800000000)
        let account = ProviderAccount(provider: .codex, nickname: "a", subject: "s", scope: "w")
        let snapshot = QuotaSnapshot(accountID: account.id, subject: "s", scope: "w", observedAt: now,
            windows: [QuotaWindow(id: "q", name: "q", unit: .percent, used: 50, resetsAt: now.addingTimeInterval(30))])
        var schedule = RefreshSchedule()
        schedule.succeeded(snapshot, account: account, now: now)
        XCTAssertFalse(schedule.shouldRefresh(account.id, now: now.addingTimeInterval(29), force: false))
        XCTAssertTrue(schedule.shouldRefresh(account.id, now: now.addingTimeInterval(30), force: false))
        schedule.failed(account.id, now: now, retryAt: nil)
        XCTAssertFalse(schedule.shouldRefresh(account.id, now: now.addingTimeInterval(119), force: false))
        XCTAssertTrue(schedule.shouldRefresh(account.id, now: now.addingTimeInterval(120), force: false))
        XCTAssertTrue(schedule.shouldRefresh(account.id, now: now, force: true))
    }
    func testAccountSnoozeSuppressesOtherWindowAndQuietHoursCrossMidnight() {
        let now = ISO8601DateFormatter().date(from: "2026-11-03T05:00:00Z")! // 11 PM Chicago
        let account = ProviderAccount(provider: .codex, nickname: "a", subject: "s", scope: "w")
        let alert = AlertEvent(id: "new", accountID: account.id, windowID: "weekly", title: "Low", detail: "", createdAt: now)
        var state = PersistedState(); state.accounts = [account]
        XCTAssertTrue(AlertDeliveryPolicy.canDeliver(alert, state: state, now: now))
        state.settings.quietHours = true
        XCTAssertFalse(AlertDeliveryPolicy.canDeliver(alert, state: state, now: now))
        state.settings.quietHours = false
        state.alerts = [AlertEvent(id: "old", accountID: account.id, windowID: "session", title: "Low", detail: "", createdAt: now, snoozedUntil: now.addingTimeInterval(3600))]
        XCTAssertFalse(AlertDeliveryPolicy.canDeliver(alert, state: state, now: now))
        XCTAssertTrue(AlertDeliveryPolicy.canDeliver(alert, state: state, now: now.addingTimeInterval(3600)))
    }
}

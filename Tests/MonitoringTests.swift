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
    func testAccountSnoozeSurvivesLegacyMigrationAndHistoryRemoval() throws {
        let now = Date(timeIntervalSince1970: 1800000000)
        let account = ProviderAccount(provider: .codex, nickname: "a", subject: "s", scope: "w")
        let alert = AlertEvent(id: "old", accountID: account.id, windowID: "session", title: "Low", detail: "", createdAt: now,
                               snoozedUntil: now.addingTimeInterval(3600))
        var state = PersistedState(); state.accounts = [account]; state.alerts = [alert]
        let encoded = try JSONEncoder().encode(state)
        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        legacy.removeValue(forKey: "snoozedAccounts")
        var migrated = try JSONDecoder().decode(PersistedState.self, from: JSONSerialization.data(withJSONObject: legacy))
        migrated.alerts.removeAll()
        let reopened = try JSONDecoder().decode(PersistedState.self, from: JSONEncoder().encode(migrated))
        var next = alert; next.id = "new"; next.snoozedUntil = nil
        XCTAssertFalse(AlertDeliveryPolicy.canDeliver(next, state: reopened, now: now))
        XCTAssertTrue(AlertDeliveryPolicy.canDeliver(next, state: reopened, now: now.addingTimeInterval(3600)))
    }

    func testIconReflectsCurrentQuotaIndependentlyOfPopupDelivery() {
        let now = Date(timeIntervalSince1970: 1800000000)
        let account = ProviderAccount(provider: .codex, nickname: "a", subject: "s", scope: "w")
        var state = PersistedState(); state.accounts = [account]
        state.settings.notifications = false; state.settings.quietHours = true
        state.snoozedAccounts[account.id] = now.addingTimeInterval(3600)
        state.snapshots[account.id] = QuotaSnapshot(accountID: account.id, subject: "s", scope: "w", observedAt: now,
            windows: [QuotaWindow(id: "q", name: "q", unit: .percent, used: 95)])
        XCTAssertEqual(IconAlertPolicy.evaluate(state: state, now: now)?.severity, .critical)
        state.accounts[0].enabled = false
        XCTAssertNil(IconAlertPolicy.evaluate(state: state, now: now))
        state.accounts[0].enabled = true
        state.settings.alertOnIcon = false
        XCTAssertNil(IconAlertPolicy.evaluate(state: state, now: now))
    }

    func testMonitorAvailabilityRejectsMissingStaleAndMismatchedUsage() {
        var state = PersistedState()
        XCTAssertEqual(MonitorAvailability.evaluate(state).notice, "No Connected Accounts")
        let account = ProviderAccount(provider: .codex, nickname: "a", subject: "s", scope: "w")
        state.accounts = [account]
        XCTAssertTrue(MonitorAvailability.evaluate(state).needsAttention)
        var snapshot = QuotaSnapshot(accountID: account.id, subject: "s", scope: "w", observedAt: .now,
            windows: [QuotaWindow(id: "q", name: "q", unit: .percent, used: 10)])
        state.snapshots[account.id] = snapshot
        XCTAssertFalse(MonitorAvailability.evaluate(state).needsAttention)
        snapshot.health = .stale; state.snapshots[account.id] = snapshot
        XCTAssertTrue(MonitorAvailability.evaluate(state).needsAttention)
        snapshot.health = .healthy; snapshot.usageAllowed = false; state.snapshots[account.id] = snapshot
        XCTAssertEqual(MonitorAvailability.evaluate(state).notice, "Provider Reports Usage Is Paused")
        snapshot.usageAllowed = true; snapshot.subject = "different"; state.snapshots[account.id] = snapshot
        XCTAssertTrue(MonitorAvailability.evaluate(state).needsAttention)
        state.accounts[0].enabled = false
        XCTAssertEqual(MonitorAvailability.evaluate(state).notice, "Monitoring Paused")
    }

    func testMonitorSummarySelectsSeverityThenLeastRemaining() {
        let account = ProviderAccount(provider: .codex, nickname: "a", subject: "s", scope: "w")
        var state = PersistedState(); state.accounts = [account]
        state.snapshots[account.id] = QuotaSnapshot(accountID: account.id, subject: "s", scope: "w", observedAt: .now,
            windows: [QuotaWindow(id: "healthy", name: "healthy", unit: .percent, used: 10),
                      QuotaWindow(id: "critical", name: "critical", unit: .percent, used: 95),
                      QuotaWindow(id: "lower", name: "lower", unit: .percent, used: 98)])
        XCTAssertEqual(MonitorAvailability.evaluate(state).windowID, "lower")
        XCTAssertEqual(MonitorAvailability.evaluate(state).accountID, account.id)
        state.accounts[0].enabled = false
        XCTAssertNil(MonitorAvailability.evaluate(state).windowID)
    }

    func testTimedAlertIncludesExactLocalTimeAndRejectsNonLiveHealth() {
        let now = Date(timeIntervalSince1970: 1800000000)
        let reset = now.addingTimeInterval(1800)
        let account = ProviderAccount(provider: .codex, nickname: "Work", subject: "s", scope: "w")
        let settings = RadarSettings()
        var snapshot = QuotaSnapshot(accountID: account.id, subject: "s", scope: "w", observedAt: now,
            windows: [QuotaWindow(id: "q", name: "Weekly", unit: .percent, used: 10, resetsAt: reset)])
        let reminders = AlertEvaluator.evaluate(account: account, previous: nil, current: snapshot, settings: settings, now: now).filter(\.isRefreshReminder)
        XCTAssertEqual(reminders.count, 1)
        XCTAssertTrue(reminders.first?.detail.contains(Format.date(reset, zone: settings.zone)) == true)
        XCTAssertTrue(reminders.first?.detail.contains("Work") == true)
        for health in [SourceHealth.demo, .stale, .offline, .authenticationRequired] {
            snapshot.health = health
            XCTAssertTrue(AlertEvaluator.evaluate(account: account, previous: nil, current: snapshot, settings: settings, now: now).isEmpty)
        }
    }

}

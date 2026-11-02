import XCTest
import SQLite3
@testable import AITokenScrooge

final class MonitoringTests: XCTestCase {
    @MainActor
    func testFailedAlertActionSavePreservesBannerAndStoredState() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("alerts.db")
        let database = try LocalStore(url: url)
        let alert = AlertEvent(id: "test-save-failure", accountID: "account", title: "Test", detail: "Test", createdAt: .now)
        var original = PersistedState()
        original.alerts = [alert]
        try await database.save(original)
        let store = AppStore(database: database)
        await store.load()
        store.activeAlert = alert
        var connection: OpaquePointer?
        XCTAssertEqual(sqlite3_open(url.path, &connection), SQLITE_OK)
        defer { sqlite3_close(connection) }
        XCTAssertEqual(sqlite3_exec(connection, "CREATE TRIGGER reject_alert_save BEFORE UPDATE ON state BEGIN SELECT RAISE(ABORT, 'injected save failure'); END;", nil, nil, nil), SQLITE_OK)
        store.dismissAlert(alert.id)
        await store.waitForPendingMutations()
        XCTAssertEqual(store.activeAlert, alert)
        XCTAssertEqual(store.state.alerts, [alert])
        XCTAssertNotNil(store.errorMessage)
        store.errorMessage = nil
        store.snooze(alert.id, minutes: 15)
        await store.waitForPendingMutations()
        XCTAssertEqual(store.activeAlert, alert)
        XCTAssertEqual(store.state.alerts, [alert])
        XCTAssertTrue(store.state.snoozedAccounts.isEmpty)
        XCTAssertNotNil(store.errorMessage)
        let persisted = try await database.load()
        XCTAssertEqual(persisted.alerts, [alert])
        XCTAssertTrue(persisted.snoozedAccounts.isEmpty)
    }
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

    func testReminderCatchUpChoosesNearestAndHighestSeverityTie() {
        let now = Date(timeIntervalSince1970: 1800000000)
        let reminders = [
            TimedReminder(id: "day", amount: 1, unit: "Days", severity: .critical),
            TimedReminder(id: "info", amount: 1, unit: "Hours", severity: .info),
            TimedReminder(id: "critical", amount: 1, unit: "Hours", severity: .critical),
            TimedReminder(id: "invalid", amount: 1, unit: "Minutes", severity: .critical)
        ]
        XCTAssertEqual(TimedReminder.due(reminders, at: now.addingTimeInterval(1800), now: now)?.id, "critical")
        XCTAssertEqual(TimedReminder.due(reminders, at: now.addingTimeInterval(3601), now: now)?.id, "day")
        XCTAssertNil(TimedReminder.due(reminders, at: now, now: now))
        XCTAssertNil(TimedReminder.due(reminders, at: now.addingTimeInterval(-1), now: now))
        XCTAssertNil(TimedReminder.due(reminders, at: now.addingTimeInterval(86401), now: now))
    }

    func testMovingResetEstimateDoesNotRepeatSameReminderMilestone() {
        let now = Date(timeIntervalSince1970: 1800000000)
        let account = ProviderAccount(provider: .codex, nickname: "Work", subject: "s", scope: "w")
        var settings = RadarSettings()
        settings.quotaRefreshReminders = [TimedReminder(id: "hour", amount: 1, unit: "Hours", severity: .warning)]
        let previous = QuotaSnapshot(accountID: account.id, subject: "s", scope: "w", observedAt: now.addingTimeInterval(-120),
            windows: [QuotaWindow(id: "q", name: "Weekly", unit: .percent, used: 10, resetsAt: now.addingTimeInterval(1800))])
        var current = previous; current.observedAt = now
        current.windows[0].resetsAt = now.addingTimeInterval(2100)
        XCTAssertFalse(AlertEvaluator.evaluate(account: account, previous: previous, current: current, settings: settings, now: now).contains(where: \.isRefreshReminder))
        current.windows[0].resetsAt = now.addingTimeInterval(3000)
        XCTAssertTrue(AlertEvaluator.evaluate(account: account, previous: previous, current: current, settings: settings, now: now).contains(where: \.isRefreshReminder))
    }

    func testWindowMutePreservesOtherQuotaAndMutesReserveOnlyWhenAllMuted() {
        let now = Date(timeIntervalSince1970: 1800000000)
        let account = ProviderAccount(provider: .codex, nickname: "Work", subject: "s", scope: "w")
        var settings = RadarSettings()
        let snapshot = QuotaSnapshot(accountID: account.id, subject: "s", scope: "w", observedAt: now,
            windows: [QuotaWindow(id: "session", name: "Session", unit: .percent, used: 95),
                      QuotaWindow(id: "weekly", name: "Weekly", unit: .percent, used: 98)],
            reserve: ResetReserve(availableCount: 1, credits: [ResetCredit(id: "credit", status: "available", expiresAt: now.addingTimeInterval(1800))]))
        settings.disabledCapacityAlerts = [.init(accountID: account.id, windowID: "session")]
        let partial = AlertEvaluator.evaluate(account: account, previous: nil, current: snapshot, settings: settings, now: now)
        XCTAssertFalse(partial.contains { $0.windowID == "session" })
        XCTAssertTrue(partial.contains { $0.windowID == "weekly" })
        XCTAssertTrue(partial.contains { $0.reminderID != nil && !$0.isRefreshReminder })
        settings.disabledCapacityAlerts.append(.init(accountID: account.id, windowID: "weekly"))
        XCTAssertTrue(AlertEvaluator.evaluate(account: account, previous: nil, current: snapshot, settings: settings, now: now).isEmpty)
        XCTAssertFalse(AlertEvaluator.isEnabled(partial.first { $0.windowID == "weekly" }!, settings: settings, snapshot: snapshot))
    }

    func testWindowThresholdOverridesDoNotLeakToOtherAccountsOrWindows() {
        var settings = RadarSettings()
        settings.rules = [AlertRule(accountID: "a", thresholds: AlertThresholds(warning: 40, critical: 20, info: 60)),
                          AlertRule(accountID: "a", windowID: "session", thresholds: AlertThresholds(warning: 25, critical: 5, info: 45))]
        XCTAssertEqual(settings.rule(accountID: "a", windowID: "session").thresholds?.critical, 5)
        XCTAssertEqual(settings.rule(accountID: "a", windowID: "weekly").thresholds?.critical, 20)
        XCTAssertEqual(settings.rule(accountID: "b", windowID: "session").thresholds, settings.thresholds)
    }

}

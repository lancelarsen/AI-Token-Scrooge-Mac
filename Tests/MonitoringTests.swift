import XCTest
import AppKit
import UserNotifications
import SQLite3
@testable import AITokenScrooge

final class MonitoringTests: XCTestCase {
    func testProviderProcessesDoNotInheritOtherCredentialsOrRuntimeInjection() {
        let dangerous = ["OPENAI_API_KEY", "CODEX_HOME", "ANTHROPIC_API_KEY", "CLAUDE_CONFIG_DIR", "GH_TOKEN", "GITHUB_TOKEN", "AZURE_OPENAI_ENDPOINT", "GEMINI_API_KEY", "GOOGLE_APPLICATION_CREDENTIALS", "AWS_PROFILE", "NODE_OPTIONS", "NODE_PATH", "BUN_OPTIONS", "DYLD_INSERT_LIBRARIES", "LD_PRELOAD", "github_token"]
        var environment = Dictionary(uniqueKeysWithValues: dangerous.map { ($0, "fixture") })
        environment["HOME"] = "/Users/example"; environment["PATH"] = "/usr/bin"; environment["LANG"] = "en_US.UTF-8"
        XCTAssertEqual(CLIEnvironment.sanitized(environment), ["HOME": "/Users/example", "PATH": "/usr/bin", "LANG": "en_US.UTF-8"])
    }

    @MainActor
    func testPendingCredentialIsDurableAndClearedWithSuccessfulConnection() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let database = try LocalStore(url: directory.appendingPathComponent("pending.db"))
        let store = AppStore(database: database)
        await store.load()
        let id = UUID().uuidString
        try await store.stageCredential(provider: .codex, id: id)
        let pending = try await database.load()
        XCTAssertEqual(pending.retiredAccounts.map(\.credentialID), [id])
        let reopened = AppStore(database: database)
        await reopened.load()
        XCTAssertEqual(reopened.state.retiredAccounts.map(\.credentialID), [id])
        let account = ProviderAccount(provider: .codex, nickname: "A", subject: "s", scope: "w", credentialID: id)
        let snapshot = QuotaSnapshot(accountID: account.id, subject: "s", scope: "w", observedAt: .now, windows: [])
        try await store.acceptConnection(account, snapshot: snapshot, replacing: nil)
        store.endCredentialAttempt(id)
        let committed = try await database.load()
        XCTAssertTrue(committed.retiredAccounts.isEmpty)
        XCTAssertEqual(committed.accounts.first?.credentialID, id)
    }

    func testOwnedProfilesRejectRedirectedDirectoriesAndContents() throws {
        let temporary = FileManager.default.temporaryDirectory.path
        let physical = temporary.hasPrefix("/var/") ? "/private" + temporary : temporary
        let base = URL(fileURLWithPath: physical).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: base) }
        let id = UUID().uuidString
        let profile = try OwnedProfileDirectory.directory(provider: .codex, id: id, base: base)
        let attributes = try FileManager.default.attributesOfItem(atPath: profile.path)
        XCTAssertEqual((attributes[.posixPermissions] as? NSNumber)?.intValue, 0o700)
        let outside = base.appendingPathComponent("outside")
        try Data("keep".utf8).write(to: outside)
        let link = profile.appendingPathComponent("auth.json")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: outside)
        XCTAssertThrowsError(try OwnedProfileDirectory.directory(provider: .codex, id: id, base: base))
        XCTAssertThrowsError(try OwnedProfileDirectory.remove(provider: .codex, id: id, base: base))
        XCTAssertEqual(try String(contentsOf: outside, encoding: .utf8), "keep")
        try FileManager.default.removeItem(at: link)
        try OwnedProfileDirectory.remove(provider: .codex, id: id, base: base)
        try FileManager.default.createSymbolicLink(at: profile, withDestinationURL: base)
        XCTAssertThrowsError(try OwnedProfileDirectory.directory(provider: .codex, id: id, base: base))
        XCTAssertThrowsError(try OwnedProfileDirectory.directory(provider: .claude, id: "../outside", base: base))
    }

    func testNativeNotificationPermissionErrorProvidesSettingsRecovery() {
        let denied = NSError(domain: UNErrorDomain, code: UNError.Code.notificationsNotAllowed.rawValue)
        XCTAssertTrue(NotificationError.explainingPermission(denied).localizedDescription.contains("Allow notifications"))
        let unrelated = NSError(domain: "StorageFailure", code: denied.code,
                                userInfo: [NSLocalizedDescriptionKey: "Original storage failure"])
        XCTAssertEqual(NotificationError.explainingPermission(unrelated).localizedDescription, "Original storage failure")
    }

    @MainActor
    func testNotificationDenialKeepsUndeliveredHistoryAndBanner() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let database = try LocalStore(url: directory.appendingPathComponent("notifications.db"))
        var original = PersistedState()
        original.settings.soundVolume = 0
        try await database.save(original)
        let delivery = NotificationDeliveryFixture(denied: true)
        let store = AppStore(database: database, notifications: delivery)
        await store.load()
        await store.sendTestNotification()
        XCTAssertEqual(store.state.alerts.count, 1)
        XCTAssertFalse(try XCTUnwrap(store.state.alerts.first).delivered)
        XCTAssertEqual(store.activeAlert?.id, store.state.alerts.first?.id)
        XCTAssertTrue(store.errorMessage?.contains("recorded in Alert History") == true)
        let persisted = try await database.load()
        XCTAssertEqual(persisted.alerts, store.state.alerts)
        let enqueued = await delivery.enqueued
        XCTAssertTrue(enqueued.isEmpty)
    }

    @MainActor
    func testNotificationIsMarkedDeliveredOnlyAfterEnqueueCompletes() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let database = try LocalStore(url: directory.appendingPathComponent("notifications.db"))
        var original = PersistedState()
        original.settings.soundVolume = 0
        try await database.save(original)
        let delivery = NotificationDeliveryFixture(denied: false)
        let store = AppStore(database: database, notifications: delivery)
        await store.load()
        let sending = Task { await store.sendTestNotification() }
        await delivery.waitForEnqueue()
        XCTAssertFalse(try XCTUnwrap(store.state.alerts.first).delivered)
        let before = try await database.load()
        XCTAssertFalse(try XCTUnwrap(before.alerts.first).delivered)
        await delivery.finishEnqueue()
        await sending.value
        XCTAssertTrue(try XCTUnwrap(store.state.alerts.first).delivered)
        let after = try await database.load()
        XCTAssertEqual(after.alerts, store.state.alerts)
    }

    @MainActor
    func testDismissalDuringNotificationEnqueueCancelsWithoutMarkingDelivered() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let database = try LocalStore(url: directory.appendingPathComponent("notifications.db"))
        var original = PersistedState()
        original.settings.soundVolume = 0
        try await database.save(original)
        let delivery = NotificationDeliveryFixture(denied: false)
        let store = AppStore(database: database, notifications: delivery)
        await store.load()
        let sending = Task { await store.sendTestNotification() }
        await delivery.waitForEnqueue()
        let id = try XCTUnwrap(store.state.alerts.first?.id)
        store.dismissAlert(id)
        await store.waitForPendingMutations()
        await delivery.finishEnqueue()
        await sending.value
        XCTAssertNil(store.activeAlert)
        XCTAssertTrue(try XCTUnwrap(store.state.alerts.first).dismissed)
        XCTAssertFalse(try XCTUnwrap(store.state.alerts.first).delivered)
        let cancelled = await delivery.cancelled
        XCTAssertTrue(cancelled.contains(id))
        let persisted = try await database.load()
        XCTAssertEqual(persisted.alerts, store.state.alerts)
    }

    @MainActor
    func testHorizonWheelDirectionAndTrackpadScaling() {
        XCTAssertEqual(HorizonWheelRouting.WheelView.horizontalDelta(x: 0, y: -3, precise: false), 60)
        XCTAssertEqual(HorizonWheelRouting.WheelView.horizontalDelta(x: 0, y: 3, precise: false), -60)
        XCTAssertEqual(HorizonWheelRouting.WheelView.horizontalDelta(x: -8, y: 2, precise: true), 8)
        XCTAssertEqual(HorizonWheelRouting.WheelView.horizontalDelta(x: 1, y: -6, precise: true), 6)
        XCTAssertEqual(HorizonWheelRouting.WheelView.horizontalDelta(x: 0, y: 0, precise: true), 0)
    }

    @MainActor
    func testHistoryPointerCoordinatesAndTrackingLifecycle() throws {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 400),
                              styleMask: [.borderless], backing: .buffered, defer: true)
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 400))
        window.contentView = root
        window.acceptsMouseMovedEvents = false
        let tracker = HistoryPointerTracking.TrackingView(frame: NSRect(x: 40, y: 50, width: 600, height: 300))
        root.addSubview(tracker)
        XCTAssertTrue(window.acceptsMouseMovedEvents, "Attaching history must enable native mouse movement delivery")
        var locations: [CGPoint?] = []
        tracker.onMove = { locations.append($0) }
        tracker.updateTrackingAreas()
        tracker.updateTrackingAreas()
        XCTAssertEqual(tracker.trackingAreas.count, 1, "Layout updates must replace tracking areas rather than duplicate callbacks")
        XCTAssertNil(tracker.hitTest(CGPoint(x: 75, y: 80)), "Tracking must not intercept event buttons or scrolling")
        let event = try XCTUnwrap(NSEvent.mouseEvent(with: .mouseMoved,
            location: CGPoint(x: 75, y: 320), modifierFlags: [], timestamp: 0,
            windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 0, pressure: 0))
        tracker.mouseMoved(with: event)
        XCTAssertEqual(locations.count, 1)
        XCTAssertEqual(locations[0], CGPoint(x: 35, y: 30), "History uses top-left coordinates within the full timeline, not window coordinates")
        tracker.showPopup("OpenAI / Work · Pro\nWeekly History\n57% Used")
        let popup = try XCTUnwrap(NSApp.windows.first { $0.title == "Usage History Details" && $0.isVisible })
        XCTAssertTrue(popup.ignoresMouseEvents)
        XCTAssertGreaterThan(popup.frame.width, 100)
        XCTAssertLessThanOrEqual(popup.frame.width, 450)
        tracker.pinned = true
        tracker.mouseExited(with: event)
        tracker.mouseMoved(with: event)
        XCTAssertTrue(popup.isVisible)
        XCTAssertEqual(locations.count, 1)
        tracker.pinned = false
        tracker.mouseExited(with: event)
        XCTAssertFalse(popup.isVisible)
        XCTAssertEqual(locations.count, 2)
        XCTAssertNil(locations[1], "Leaving history must clear its details and guide")
        tracker.removeFromSuperview()
    }

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
        XCTAssertEqual(sqlite3_exec(connection, "DROP TRIGGER reject_alert_save;", nil, nil, nil), SQLITE_OK)
        store.errorMessage = nil
        store.dismissAlert(alert.id)
        await store.waitForPendingMutations()
        XCTAssertNil(store.activeAlert)
        XCTAssertTrue(store.state.alerts[0].dismissed)
        XCTAssertNil(store.errorMessage)
        let recovered = try await database.load()
        XCTAssertTrue(recovered.alerts[0].dismissed)
        XCTAssertTrue(recovered.snoozedAccounts.isEmpty)
    }
    @MainActor
    func testQueuedAlertActionsPreserveNewerBannerAndEachOthersChanges() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let database = try LocalStore(url: directory.appendingPathComponent("actions.db"))
        let old = AlertEvent(id: UUID().uuidString, accountID: "account", title: "Old", detail: "Test", createdAt: .now)
        let newer = AlertEvent(id: UUID().uuidString, accountID: "account", title: "New", detail: "Test", createdAt: .now)
        var initial = PersistedState()
        initial.alerts = [old, newer]
        initial.settings.sound = false
        try await database.save(initial)
        let store = AppStore(database: database)
        await store.load()
        store.activeAlert = old
        store.dismissAlert(old.id)
        store.snooze(old.id, minutes: 15)
        // Both actions captured the old banner before their queued writes execute.
        store.activeAlert = newer
        await store.waitForPendingMutations()
        XCTAssertEqual(store.activeAlert, newer)
        let changed = try XCTUnwrap(store.state.alerts.first { $0.id == old.id })
        XCTAssertTrue(changed.dismissed)
        let deadline = try XCTUnwrap(changed.snoozedUntil)
        XCTAssertEqual(store.state.snoozedAccounts[old.accountID], deadline)
        XCTAssertEqual(store.state.alerts.first { $0.id == newer.id }, newer)
        XCTAssertNil(store.errorMessage)
        let persisted = try await database.load()
        XCTAssertEqual(persisted.alerts, store.state.alerts)
        XCTAssertEqual(persisted.snoozedAccounts[old.accountID], deadline)
    }
    @MainActor
    func testDemoAlertActionsDoNotOverwriteRealState() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let database = try LocalStore(url: directory.appendingPathComponent("demo-isolation.db"))
        let realAlert = AlertEvent(id: UUID().uuidString, accountID: "real-account", title: "Real", detail: "Test", createdAt: .now)
        var initial = PersistedState()
        initial.alerts = [realAlert]
        initial.settings.sound = false
        try await database.save(initial)
        let store = AppStore(database: database)
        await store.load()
        store.dismissAlert(realAlert.id)
        store.enterDemo()
        await store.waitForPendingMutations()
        XCTAssertTrue(store.isDemo)
        let demoAlert = AlertEvent(id: UUID().uuidString, accountID: "demo-account", title: "Demo", detail: "Test", createdAt: .now)
        store.edit { $0.alerts.append(demoAlert); $0.settings.sound = false }
        store.snooze(demoAlert.id, minutes: 15)
        store.exitDemo()
        await store.waitForPendingMutations()
        XCTAssertFalse(store.isDemo)
        XCTAssertEqual(store.state.alerts.count, 1)
        XCTAssertEqual(store.state.alerts.first?.id, realAlert.id)
        XCTAssertEqual(store.state.alerts.first?.dismissed, true)
        XCTAssertTrue(store.state.snoozedAccounts.isEmpty)
        let persisted = try await database.load()
        XCTAssertEqual(persisted.alerts, store.state.alerts)
        XCTAssertTrue(persisted.snoozedAccounts.isEmpty)
        XCTAssertNil(store.errorMessage)
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
        state.settings.quietStartHour = 22
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
        state.settings.quietHours = false
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

private actor NotificationDeliveryFixture: NotificationDelivering {
    let denied: Bool
    private(set) var enqueued: [String] = []
    private(set) var cancelled: [String] = []
    private var enqueueGate: CheckedContinuation<Void, Never>?
    private var startWaiter: CheckedContinuation<Void, Never>?
    init(denied: Bool) { self.denied = denied }
    func authorize() async throws { if denied { throw NotificationError.denied } }
    func enqueue(id: String, title: String, detail: String, delay: TimeInterval?) async throws {
        enqueued.append(id)
        await withCheckedContinuation { continuation in
            enqueueGate = continuation
            startWaiter?.resume()
            startWaiter = nil
        }
    }
    func waitForEnqueue() async {
        if !enqueued.isEmpty { return }
        await withCheckedContinuation { startWaiter = $0 }
    }
    func finishEnqueue() { enqueueGate?.resume(); enqueueGate = nil }
    func cancel(_ id: String) { cancelled.append(id) }
}

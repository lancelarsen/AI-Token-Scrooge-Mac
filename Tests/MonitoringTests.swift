import XCTest
import Observation
import AppKit
import UserNotifications
import SQLite3
@testable import AITokenScrooge

private final class TooltipTestWindow: NSWindow {
    var testIsKey = false
    override var isKeyWindow: Bool { testIsKey }
}

final class MonitoringTests: XCTestCase {
    @MainActor
    func testManualRefreshPublishesAndPersistsFastAccountWhileFirstAccountIsPending() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let database = try LocalStore(url: directory.appendingPathComponent("refresh.db"))
        let slow = ProviderAccount(provider: .codex, nickname: "Slow", subject: "slow", scope: "work")
        let fast = ProviderAccount(provider: .codex, nickname: "Fast", subject: "fast", scope: "work")
        var initial = PersistedState()
        initial.accounts = [slow, fast]
        initial.settings.sound = false
        try await database.save(initial)
        let reader = SuspendedRefreshFixture(holding: slow.id)
        defer { reader.release() }
        let store = AppStore(database: database, refreshAccount: { await reader.read($0) })
        await store.load()

        let published = expectation(description: "Fast account published while the slow account is suspended")
        withObservationTracking { _ = store.state.snapshots[fast.id] } onChange: { published.fulfill() }
        let historyUpdated = expectation(description: "Fast account appeared in the timeline")
        withObservationTracking { _ = store.history } onChange: { historyUpdated.fulfill() }
        let refresh = Task { await store.refreshByUser() }
        await fulfillment(of: [reader.started, published, historyUpdated], timeout: 3)
        XCTAssertTrue(store.isRefreshing)
        XCTAssertEqual(store.state.snapshots[fast.id]?.health, .healthy)
        XCTAssertEqual(store.history.map(\.snapshot.accountID), [fast.id])
        if !store.canRequestRefresh {
            let available = expectation(description: "Manual refresh became available again")
            withObservationTracking { _ = store.canRequestRefresh } onChange: { available.fulfill() }
            await fulfillment(of: [available], timeout: 3)
        }
        XCTAssertTrue(store.canRequestRefresh)
        let during = try await database.load()
        XCTAssertEqual(during.snapshots[fast.id], store.state.snapshots[fast.id])
        XCTAssertNil(during.snapshots[slow.id])

        // Each manual retry can update the free account. Both clicks should queue
        // only one follow-up for the account still doing its first read.
        var retries: [Task<Void, Never>] = []
        for count in 2...3 {
            // Publishing the snapshot precedes releasing the provider's active read.
            // Wait for the same availability gate that enables the Refresh button.
            if !store.canRequestRefresh {
                let available = expectation(description: "Retry refresh became available")
                withObservationTracking { _ = store.canRequestRefresh } onChange: { available.fulfill() }
                await fulfillment(of: [available], timeout: 3)
            }
            XCTAssertTrue(store.canRequestRefresh)
            let updated = expectation(description: "Fast account published reading \(count)")
            withObservationTracking { _ = store.state.snapshots[fast.id] } onChange: { updated.fulfill() }
            retries.append(Task { await store.refreshByUser() })
            await fulfillment(of: [updated], timeout: 3)
            XCTAssertEqual(store.state.snapshots[fast.id]?.windows.first?.used, Decimal(count))
        }
        XCTAssertEqual(reader.calls[slow.id], 1)
        reader.release()
        await refresh.value
        for retry in retries { await retry.value }
        await fulfillment(of: [reader.followUpStarted], timeout: 3)
        await store.waitForPendingMutations()
        XCTAssertFalse(store.isRefreshing)
        XCTAssertEqual(reader.calls, [slow.id: 2, fast.id: 3])
        XCTAssertEqual(store.state.snapshots[slow.id]?.windows.first?.used, 2)
        let after = try await database.load()
        XCTAssertEqual(after.snapshots, store.state.snapshots)
    }

    @MainActor
    func testAccountRefreshDeadlineCancelsSlowReadAndKeepsOtherAccountFresh() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let database = try LocalStore(url: directory.appendingPathComponent("deadline.db"))
        let slow = ProviderAccount(provider: .codex, nickname: "Slow", subject: "slow", scope: "personal")
        let fast = ProviderAccount(provider: .copilot, nickname: "Fast", subject: "fast", scope: "personal")
        var initial = PersistedState()
        initial.accounts = [slow, fast]
        initial.snapshots[slow.id] = QuotaSnapshot(accountID: slow.id, subject: slow.subject,
            scope: slow.scope, observedAt: .now,
            windows: [QuotaWindow(id: "weekly", name: "Weekly", unit: .percent, used: 40, limit: 100)])
        try await database.save(initial)
        let canceled = expectation(description: "Timed-out provider read canceled")
        let store = AppStore(database: database, refreshTimeout: .milliseconds(100), refreshAccount: { account in
            if account.id == slow.id {
                do { try await Task.sleep(for: .seconds(30)) }
                catch { canceled.fulfill(); throw error }
            }
            return QuotaSnapshot(accountID: account.id, subject: account.subject, scope: account.scope,
                observedAt: .now, windows: [QuotaWindow(id: "monthly", name: "Monthly", unit: .percent, used: 10, limit: 100)])
        })
        await store.load()
        await store.refreshByUser()
        await fulfillment(of: [canceled], timeout: 2)
        XCTAssertFalse(store.isRefreshing)
        XCTAssertEqual(store.state.snapshots[slow.id]?.health, .offline)
        XCTAssertTrue(store.state.snapshots[slow.id]?.message?.contains("timed out") == true)
        XCTAssertEqual(store.state.snapshots[slow.id]?.windows, initial.snapshots[slow.id]?.windows)
        XCTAssertEqual(store.state.snapshots[fast.id]?.health, .healthy)
        let saved = try await database.load()
        XCTAssertEqual(saved.snapshots, store.state.snapshots)
    }

    @MainActor
    func testSettingsCloseWaitsForEditsAndKeepsFailedSavesVisible() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("settings-close.db")
        let database = try LocalStore(url: url)
        let original = PersistedState()
        try await database.save(original)
        let store = AppStore(database: database)
        await store.load()
        var connection: OpaquePointer?
        XCTAssertEqual(sqlite3_open(url.path, &connection), SQLITE_OK)
        defer { sqlite3_close(connection) }
        XCTAssertEqual(sqlite3_exec(connection, "CREATE TRIGGER reject_settings BEFORE UPDATE ON state BEGIN SELECT RAISE(ABORT, 'injected save failure'); END;", nil, nil, nil), SQLITE_OK)
        store.edit { $0.settings.sound.toggle() }
        let canCloseAfterFailure = await store.finishSettingsEdits()
        XCTAssertFalse(canCloseAfterFailure)
        XCTAssertNotNil(store.settingsSaveError)
        XCTAssertEqual(store.state.settings, original.settings)
        let failed = try await database.load()
        XCTAssertEqual(failed.settings, original.settings)

        // Preview changes must not clear or inherit the failed real save.
        store.enterDemo()
        let demoCanClose = await store.finishSettingsEdits()
        XCTAssertTrue(demoCanClose)
        store.edit { $0.settings.sound.toggle() }
        await store.waitForPendingMutations()
        store.exitDemo()
        let realCanClose = await store.finishSettingsEdits()
        XCTAssertFalse(realCanClose)

        XCTAssertEqual(sqlite3_exec(connection, "DROP TRIGGER reject_settings", nil, nil, nil), SQLITE_OK)
        store.errorMessage = "Unrelated provider notice"
        store.edit { $0.settings.sound.toggle() }
        let canCloseAfterRecovery = await store.finishSettingsEdits()
        XCTAssertTrue(canCloseAfterRecovery)
        XCTAssertNil(store.settingsSaveError)
        XCTAssertEqual(store.errorMessage, "Unrelated provider notice")
        let saved = try await database.load()
        XCTAssertEqual(saved.settings.sound, !original.settings.sound)
        XCTAssertEqual(saved.settings, store.state.settings)
    }

    @MainActor
    func testKeychainReadFailurePreservesQuotaAndReportsPermission() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let database = try LocalStore(url: directory.appendingPathComponent("keychain.db"))
        let account = ProviderAccount(provider: .copilot, nickname: "Personal", subject: "test", scope: "personal")
        var initial = PersistedState()
        initial.accounts = [account]
        initial.snapshots[account.id] = QuotaSnapshot(accountID: account.id, subject: account.subject,
            scope: account.scope, observedAt: .now,
            windows: [QuotaWindow(id: "monthly", name: "Monthly", unit: .credits, used: 40, limit: 100)])
        try await database.save(initial)
        let store = AppStore(database: database, refreshAccount: { _ in throw SecretStoreError.unavailable })
        await store.load()
        await store.refreshByUser()
        let snapshot = try XCTUnwrap(store.state.snapshots[account.id])
        XCTAssertEqual(snapshot.health, .permissionRequired)
        XCTAssertTrue(snapshot.message?.contains("Keychain") == true)
        XCTAssertEqual(snapshot.windows, initial.snapshots[account.id]?.windows)
        XCTAssertFalse(store.isRefreshing)
        let saved = try await database.load()
        XCTAssertEqual(saved.snapshots[account.id], snapshot)
    }

    @MainActor
    func testNextPollStartsNewlyEnabledAccountAndDiscardsRemovedAccountsPendingResult() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let database = try LocalStore(url: directory.appendingPathComponent("poll.db"))
        let slow = ProviderAccount(provider: .claude, nickname: "Slow", subject: "slow", scope: "work")
        let later = ProviderAccount(provider: .copilot, nickname: "Later", subject: "later", scope: "personal", enabled: false)
        var initial = PersistedState()
        initial.accounts = [slow, later]
        try await database.save(initial)
        let reader = SuspendedRefreshFixture(holding: slow.id)
        defer { reader.release() }
        let store = AppStore(database: database, refreshAccount: { await reader.read($0) })
        await store.load()

        let first = Task { await store.refresh(force: false) }
        await fulfillment(of: [reader.started], timeout: 3)
        store.edit { $0.accounts[1].enabled = true }
        await store.waitForPendingMutations()
        let published = expectation(description: "Next poll published the newly enabled account")
        withObservationTracking { _ = store.state.snapshots[later.id] } onChange: { published.fulfill() }
        let next = Task { await store.refresh(force: false) }
        await fulfillment(of: [published], timeout: 3)
        XCTAssertEqual(store.state.snapshots[later.id]?.health, .healthy)

        await store.removeAccount(slow.id)
        reader.release()
        await first.value
        await next.value
        XCTAssertEqual(reader.calls, [slow.id: 1, later.id: 1])
        XCTAssertNil(store.state.snapshots[slow.id])
        let after = try await database.load()
        XCTAssertEqual(after.snapshots, store.state.snapshots)
        let history = try await database.history(accountID: slow.id, since: .distantPast)
        XCTAssertTrue(history.isEmpty)
    }

    @MainActor
    func testIdleMonitorDoesNotPublishRefreshActivityOrReloadHistory() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let database = try LocalStore(url: directory.appendingPathComponent("idle.db"))
        let store = AppStore(database: database)
        await store.load()
        let revision = store.historyRevision
        let activity = expectation(description: "Idle tick must not announce refresh activity")
        activity.isInverted = true
        withObservationTracking { _ = store.isRefreshing } onChange: { activity.fulfill() }
        await store.refresh(force: false)
        await store.refresh(force: true)
        XCTAssertEqual(store.historyRevision, revision)
        await fulfillment(of: [activity], timeout: 0.05)
    }

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
        let helpers = profile.appendingPathComponent("tmp/arg0/codex-arg0fixture")
        try FileManager.default.createDirectory(at: helpers, withIntermediateDirectories: true)
        let alias = helpers.appendingPathComponent("apply_patch")
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: outside)
        XCTAssertThrowsError(try OwnedProfileDirectory.directory(provider: .codex, id: id, base: base))
        try FileManager.default.removeItem(at: alias)
        for executable in CodexConnection.installedExecutables {
            try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: executable)
            XCTAssertNoThrow(try OwnedProfileDirectory.directory(provider: .codex, id: id, base: base))
            try FileManager.default.removeItem(at: alias)
        }
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
    func testAcceptedNotificationWithFailedDeliverySaveReportsBothOutcomes() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("delivery-save.db")
        let database = try LocalStore(url: url)
        var original = PersistedState()
        original.settings.soundVolume = 0
        try await database.save(original)
        let delivery = NotificationDeliveryFixture(denied: false)
        let store = AppStore(database: database, notifications: delivery)
        await store.load()
        let sending = Task { await store.sendTestNotification() }
        await delivery.waitForEnqueue()
        var connection: OpaquePointer?
        XCTAssertEqual(sqlite3_open(url.path, &connection), SQLITE_OK)
        defer { sqlite3_close(connection) }
        XCTAssertEqual(sqlite3_exec(connection, "CREATE TRIGGER reject_delivery_save BEFORE UPDATE ON state BEGIN SELECT RAISE(ABORT, 'injected save failure'); END;", nil, nil, nil), SQLITE_OK)
        await delivery.finishEnqueue()
        await sending.value
        XCTAssertTrue(store.errorMessage?.contains("macOS accepted the notification") == true)
        XCTAssertTrue(store.errorMessage?.contains("could not save the delivery status") == true)
        XCTAssertTrue(store.errorMessage?.contains("will not be replayed") == true)
        let alert = try XCTUnwrap(store.state.alerts.first)
        XCTAssertFalse(alert.delivered, "Failed persistence must not invent a saved delivery")
        XCTAssertEqual(store.activeAlert?.id, alert.id)
        let persisted = try await database.load()
        XCTAssertEqual(persisted.alerts, store.state.alerts)
        let enqueued = await delivery.enqueued
        XCTAssertEqual(enqueued, [alert.id])
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
    func testWindowResizeAndEscapeCancelAccountDragWithoutSaving() async throws {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
                              styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let scroll = NSScrollView(frame: window.contentView!.bounds)
        window.contentView = scroll
        let document = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 800))
        scroll.documentView = document
        let markers = (0..<2).map { index in
            NSView(frame: NSRect(x: 0, y: index * 120, width: 400, height: 100))
        }
        let dragging = AccountDragging()
        for (index, marker) in markers.enumerated() {
            document.addSubview(marker)
            dragging.register(marker, id: String(index))
        }
        let event = try XCTUnwrap(NSEvent.mouseEvent(with: .leftMouseDown,
            location: CGPoint(x: 30, y: 30), modifierFlags: [], timestamp: 0,
            windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1))
        func displaceDrag(to location: CGPoint = CGPoint(x: 30, y: 180)) async throws {
            let movement = try XCTUnwrap(NSEvent.mouseEvent(with: .leftMouseDragged,
                location: location, modifierFlags: [], timestamp: 0,
                windowNumber: window.windowNumber, context: nil, eventNumber: 1, clickCount: 1, pressure: 1))
            NSApp.postEvent(movement, atStart: true)
            try await Task.sleep(for: .milliseconds(80))
            XCTAssertTrue(dragging.moving)
            XCTAssertFalse(dragging.offsets.isEmpty, "Cancellation must be tested after the card has moved")
        }
        var savedSlots: [Int] = []
        dragging.begin(id: "0", ids: ["0", "1"], event: event) { savedSlots.append($0) }
        XCTAssertEqual(dragging.activeID, "0")
        try await displaceDrag()
        window.setContentSize(NSSize(width: 520, height: 420))
        try await Task.sleep(for: .milliseconds(250))
        XCTAssertNil(dragging.activeID)
        XCTAssertTrue(dragging.offsets.isEmpty)
        XCTAssertTrue(savedSlots.isEmpty)
        dragging.begin(id: "1", ids: ["0", "1"], event: event) { savedSlots.append($0) }
        XCTAssertEqual(dragging.activeID, "1", "Cancellation must release the input monitor for a fresh drag")
        let originalScroll = scroll.contentView.bounds.origin
        try await displaceDrag(to: CGPoint(x: 30, y: 405))
        let firstScroll = scroll.contentView.bounds.origin
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertNotEqual(scroll.contentView.bounds.origin, firstScroll, "Edge scrolling must continue while the pointer is held still")
        XCTAssertNotEqual(scroll.contentView.bounds.origin, originalScroll, "Holding a dragged card at the viewport edge must scroll")
        try await displaceDrag(to: CGPoint(x: 530, y: 405))
        let stoppedScroll = scroll.contentView.bounds.origin
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertEqual(scroll.contentView.bounds.origin, stoppedScroll, "Dragging outside the viewport must stop edge scrolling")
        let escape = try XCTUnwrap(NSEvent.keyEvent(with: .keyDown, location: .zero,
            modifierFlags: [], timestamp: 0, windowNumber: window.windowNumber,
            context: nil, characters: "\u{1b}", charactersIgnoringModifiers: "\u{1b}",
            isARepeat: false, keyCode: 53))
        NSApp.postEvent(escape, atStart: true)
        try await Task.sleep(for: .milliseconds(250))
        XCTAssertNil(dragging.activeID)
        XCTAssertTrue(dragging.offsets.isEmpty)
        XCTAssertTrue(savedSlots.isEmpty)
        XCTAssertEqual(scroll.contentView.bounds.origin, originalScroll, "Escape restores the scroll position from drag start")
    }

    @MainActor
    func testHistoryPointerCoordinatesAndTrackingLifecycle() throws {
        let window = TooltipTestWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 400),
                                       styleMask: [.borderless], backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        defer { window.close() }
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
        XCTAssertTrue(locations.isEmpty, "Inactive windows ignore pointer movement")
        window.testIsKey = true
        tracker.mouseMoved(with: event)
        XCTAssertEqual(locations.count, 1)
        XCTAssertEqual(try XCTUnwrap(locations.first), CGPoint(x: 35, y: 30), "History uses top-left coordinates within the full timeline, not window coordinates")
        let popupText = "OpenAI / Work · Pro\nWeekly History\n57% Used"
        window.testIsKey = false
        tracker.showPopup(popupText)
        XCTAssertFalse(NSApp.windows.contains { $0.title == "Usage History Details" && $0.isVisible })
        window.testIsKey = true
        tracker.showPopup(popupText)
        let popup = try XCTUnwrap(NSApp.windows.first { $0.title == "Usage History Details" && $0.isVisible })
        tracker.popupText = popupText
        tracker.setFrameOrigin(CGPoint(x: 40, y: 500))
        tracker.updateTrackingAreas()
        XCTAssertFalse(popup.isVisible, "An offscreen control must not present its tooltip")
        tracker.setFrameOrigin(CGPoint(x: 40, y: 50))
        tracker.showPopup(popupText)
        XCTAssertTrue(popup.isVisible)
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
    func testHistoryPopupDismissalClearsSelectionAndDetachesOwnerObserver() throws {
        let window = TooltipTestWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 400),
                                       styleMask: [.borderless], backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 400))
        window.contentView = root
        let tracker = HistoryPointerTracking.TrackingView(frame: NSRect(x: 40, y: 50, width: 600, height: 300))
        root.addSubview(tracker)
        window.testIsKey = true
        let text = "OpenAI / Personal · Plus\nWeekly · 74% Used\nSat, Nov 7 12:03 AM"
        var selection: String? = text
        var dismissals = 0
        tracker.onMove = { [weak tracker] point in
            if point == nil {
                selection = nil
                tracker?.popupText = nil
                dismissals += 1
            }
        }
        tracker.pinned = true
        tracker.popupText = text
        tracker.showPopup(text)
        let popup = try XCTUnwrap(NSApp.windows.first { $0.title == "Usage History Details" && $0.isVisible })

        window.testIsKey = false
        NotificationCenter.default.post(name: NSWindow.didResignKeyNotification, object: window)
        XCTAssertFalse(popup.isVisible, "Owner focus loss dismisses even pinned details")
        XCTAssertNil(selection)
        XCTAssertNil(tracker.popupText)
        XCTAssertEqual(dismissals, 1)

        window.testIsKey = true
        tracker.updateTrackingAreas()
        tracker.showPopup(tracker.popupText)
        XCTAssertFalse(popup.isVisible, "Returning to the owner must not replay cleared details")
        tracker.popupText = text
        tracker.showPopup(text)
        XCTAssertTrue(popup.isVisible, "A fresh selection can show details again")

        tracker.removeFromSuperview()
        XCTAssertFalse(popup.isVisible)
        NotificationCenter.default.post(name: NSWindow.didResignKeyNotification, object: window)
        XCTAssertEqual(dismissals, 1, "Detached tracking surfaces must release their owner observer")
    }

    @MainActor
    func testNotificationOpenLoadsSavedAlertAndRequestsItsAccount() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let database = try LocalStore(url: directory.appendingPathComponent("alerts.db"))
        let account = ProviderAccount(provider: .codex, nickname: "Personal", subject: "test", scope: "personal")
        let alert = AlertEvent(id: "saved", accountID: account.id, title: "Test", detail: "Test", createdAt: .now)
        var state = PersistedState()
        state.accounts = [account]
        state.alerts = [alert]
        try await database.save(state)
        let store = AppStore(database: database)

        for action in ["show-info", UNNotificationDefaultActionIdentifier] {
            let previousRequest = store.dashboardOpenRequest
            await ScroogeAppDelegate.handleNotification(id: alert.id, action: action, store: store)
            XCTAssertEqual(store.highlightedAccountID, account.id)
            XCTAssertNotEqual(store.dashboardOpenRequest, previousRequest)
        }
        let lastRequest = store.dashboardOpenRequest
        await ScroogeAppDelegate.handleNotification(id: "expired", action: "show-info", store: store)
        XCTAssertNotEqual(store.dashboardOpenRequest, lastRequest)
        XCTAssertNil(store.highlightedAccountID)
    }

    @MainActor
    func testNativeNotificationActionsPersistOnlyTheirTargetAlert() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let database = try LocalStore(url: directory.appendingPathComponent("actions.db"))
        let account = ProviderAccount(provider: .codex, nickname: "Personal", subject: "test", scope: "personal")
        let identifiers = ["native-dismiss", "button-dismiss", "snoozed", "untouched"]
        var state = PersistedState()
        state.accounts = [account]
        state.alerts = identifiers.map {
            AlertEvent(id: $0, accountID: account.id, title: "Test", detail: "Test", createdAt: .now)
        }
        try await database.save(state)
        let store = AppStore(database: database)
        await store.load()
        let openRequest = store.dashboardOpenRequest
        let before = Date()
        for (id, action) in [
            ("native-dismiss", UNNotificationDismissActionIdentifier),
            ("button-dismiss", "dismiss"), ("snoozed", "snooze"),
            ("missing", "dismiss"), ("missing", "snooze"), ("untouched", "unknown")
        ] {
            await ScroogeAppDelegate.handleNotification(id: id, action: action, store: store)
        }
        let saved = try await database.load()
        XCTAssertEqual(saved.alerts.count, 4)
        XCTAssertTrue(saved.alerts[0].dismissed)
        XCTAssertTrue(saved.alerts[1].dismissed)
        let deadline = try XCTUnwrap(saved.alerts[2].snoozedUntil)
        XCTAssertGreaterThanOrEqual(deadline.timeIntervalSince(before), 3600)
        XCTAssertLessThanOrEqual(deadline.timeIntervalSinceNow, 3600)
        XCTAssertEqual(saved.snoozedAccounts[account.id], deadline)
        XCTAssertEqual(saved.alerts[3], state.alerts[3])
        XCTAssertEqual(store.state.alerts, saved.alerts)
        XCTAssertEqual(store.dashboardOpenRequest, openRequest)
    }

    @MainActor
    func testSnoozingTestNotificationPreservesRealAccountAlerts() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let database = try LocalStore(url: directory.appendingPathComponent("test-snooze.db"))
        let account = ProviderAccount(provider: .codex, nickname: "Personal", subject: "test", scope: "personal")
        var state = PersistedState()
        state.accounts = [account]
        state.settings.soundVolume = 0
        let existingDeadline = Date.now.addingTimeInterval(900)
        state.snoozedAccounts[account.id] = existingDeadline
        state.alerts = [AlertEvent(id: "test/legacy", accountID: account.id,
            title: "Scrooge Notification Test", detail: "Test", createdAt: .now),
            AlertEvent(id: "real-capacity", accountID: account.id,
            title: "Low capacity", detail: "Real alert", createdAt: .now)]
        try await database.save(state)
        let store = AppStore(database: database)
        await store.load()
        store.activeAlert = state.alerts[1]
        await ScroogeAppDelegate.handleNotification(id: "test/legacy", action: "snooze", store: store)
        let saved = try await database.load()
        XCTAssertNotNil(saved.alerts[0].snoozedUntil)
        XCTAssertEqual(saved.snoozedAccounts[account.id], existingDeadline)
        XCTAssertEqual(saved.alerts[1], state.alerts[1])
        XCTAssertEqual(store.activeAlert?.id, "real-capacity")
    }

    @MainActor
    func testNotificationResponseWaitsForSavedActionAndCleanup() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let database = try LocalStore(url: directory.appendingPathComponent("response.db"))
        let alert = AlertEvent(id: "response", accountID: "account", title: "Test", detail: "Test", createdAt: .now)
        var state = PersistedState()
        state.alerts = [alert]
        state.settings.sound = false
        try await database.save(state)
        let notifications = NotificationDeliveryFixture(denied: false, holdsCancellation: true)
        let store = AppStore(database: database, notifications: notifications)
        await store.load()
        var callbackReturned = false
        let callback = Task {
            await ScroogeAppDelegate.handleNotification(id: alert.id, action: "dismiss", store: store)
            callbackReturned = true
        }
        await notifications.waitForCancellation()
        XCTAssertFalse(callbackReturned, "macOS must not receive completion while action cleanup is pending")
        let saved = try await database.load()
        XCTAssertTrue(saved.alerts[0].dismissed)
        await notifications.finishCancellation()
        await callback.value
        XCTAssertTrue(callbackReturned)
        XCTAssertTrue(store.state.alerts[0].dismissed)
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

@MainActor
private final class SuspendedRefreshFixture {
    let started = XCTestExpectation(description: "Slow account refresh started")
    let followUpStarted = XCTestExpectation(description: "Coalesced follow-up refresh started")
    private let accountID: String
    private var held = true
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private(set) var calls: [String: Int] = [:]

    init(holding accountID: String) { self.accountID = accountID }

    func read(_ account: ProviderAccount) async -> QuotaSnapshot {
        calls[account.id, default: 0] += 1
        let count = calls[account.id, default: 0]
        if account.id == accountID {
            if count == 1 { started.fulfill() }
            if count == 2 { followUpStarted.fulfill() }
            if held { await withCheckedContinuation { waiters.append($0) } }
        }
        return QuotaSnapshot(accountID: account.id, subject: account.subject, scope: account.scope,
                             observedAt: .now, windows: [QuotaWindow(id: "weekly", name: "Weekly", unit: .percent, used: Decimal(count))])
    }

    func release() {
        held = false
        for waiter in waiters { waiter.resume() }
        waiters.removeAll()
    }
}

private actor NotificationDeliveryFixture: NotificationDelivering {
    let denied: Bool
    private(set) var enqueued: [String] = []
    private(set) var cancelled: [String] = []
    private var enqueueGate: CheckedContinuation<Void, Never>?
    private var startWaiter: CheckedContinuation<Void, Never>?
    private let holdsCancellation: Bool
    private var cancellationGate: CheckedContinuation<Void, Never>?
    private var cancellationWaiter: CheckedContinuation<Void, Never>?
    init(denied: Bool, holdsCancellation: Bool = false) {
        self.denied = denied
        self.holdsCancellation = holdsCancellation
    }
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
    func cancel(_ id: String) async {
        cancelled.append(id)
        if holdsCancellation {
            await withCheckedContinuation { continuation in
                cancellationGate = continuation
                cancellationWaiter?.resume()
                cancellationWaiter = nil
            }
        }
    }
    func waitForCancellation() async {
        if cancellationGate != nil { return }
        await withCheckedContinuation { cancellationWaiter = $0 }
    }
    func finishCancellation() { cancellationGate?.resume(); cancellationGate = nil }
}

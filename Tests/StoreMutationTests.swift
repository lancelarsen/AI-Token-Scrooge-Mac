import XCTest
@testable import AITokenScrooge

@MainActor
final class StoreMutationTests: XCTestCase {
    private func makeDatabase() throws -> LocalStore {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        addTeardownBlock { try FileManager.default.removeItem(at: directory) }
        return try LocalStore(url: directory.appendingPathComponent("test.db"))
    }

    func testReconnectUsesLatestPreferencesAndRejectsStaleGeneration() async throws {
        let database = try makeDatabase()
        let original = ProviderAccount(provider: .codex, nickname: "Personal", subject: "user", scope: "workspace")
        var initial = PersistedState()
        initial.accounts = [original]
        try await database.save(initial)
        let store = AppStore(database: database)
        await store.load()

        var replacement = original
        replacement.credentialID = UUID().uuidString
        let snapshot = QuotaSnapshot(accountID: original.id, subject: original.subject, scope: original.scope, observedAt: .now, windows: [])
        store.edit {
            $0.accounts[0].nickname = "Work"
            $0.accounts[0].pollingMinutes = 15
            $0.accounts[0].lineColor = "#123456"
        }
        try await store.acceptConnection(replacement, snapshot: snapshot, replacing: original)
        let saved = try await database.load()
        let connected = try XCTUnwrap(saved.accounts.first)
        XCTAssertEqual(connected.nickname, "Work")
        XCTAssertEqual(connected.pollingMinutes, 15)
        XCTAssertEqual(connected.lineColor, "#123456")
        XCTAssertEqual(connected.credentialID, replacement.credentialID)
        XCTAssertNotEqual(connected.generation, original.generation)
        XCTAssertEqual(saved.retiredAccounts.map(\.credentialID), [original.credentialID])
        XCTAssertEqual(store.state, saved)
        do {
            try await store.acceptConnection(replacement, snapshot: snapshot, replacing: original)
            XCTFail("A second sign-in from the old generation must be rejected")
        } catch is ProviderFailure {}
        let afterStaleCommit = try await database.load()
        XCTAssertEqual(afterStaleCommit, saved)
    }

    func testReconnectRejectsAValidSnapshotFromAnotherWorkspace() async throws {
        let database = try makeDatabase()
        let original = ProviderAccount(provider: .codex, nickname: "Work", subject: "user", scope: "first")
        var initial = PersistedState()
        initial.accounts = [original]
        try await database.save(initial)
        let store = AppStore(database: database)
        await store.load()

        var replacement = original
        replacement.scope = "second"
        let snapshot = QuotaSnapshot(accountID: replacement.id, subject: replacement.subject, scope: replacement.scope, observedAt: .now, windows: [])
        do {
            try await store.acceptConnection(replacement, snapshot: snapshot, replacing: original)
            XCTFail("A different workspace must be rejected even when the snapshot matches the replacement")
        } catch AccountError.differentIdentity {}
        let saved = try await database.load()
        XCTAssertEqual(saved, initial)
        let history = try await database.history(accountID: original.id, since: .distantPast)
        XCTAssertTrue(history.isEmpty)
    }

    func testPendingRefreshCannotAttachUsageToAnotherWorkspace() async throws {
        let database = try makeDatabase()
        let account = ProviderAccount(provider: .codex, nickname: "Work", subject: "user", scope: "first")
        var initial = PersistedState()
        initial.accounts = [account]
        try await database.save(initial)

        let started = expectation(description: "Provider read started")
        let (gate, continuation) = AsyncStream<Void>.makeStream()
        let store = AppStore(database: database, refreshAccount: { requested in
            started.fulfill()
            for await _ in gate {}
            return QuotaSnapshot(accountID: requested.id, subject: requested.subject, scope: requested.scope, observedAt: .now, windows: [])
        })
        await store.load()
        let refresh = Task { await store.refresh() }
        await fulfillment(of: [started], timeout: 3)
        store.edit { $0.accounts[0].scope = "second" }
        await store.waitForPendingMutations()
        continuation.finish()
        await refresh.value

        XCTAssertTrue(store.state.snapshots.isEmpty)
        let saved = try await database.load()
        XCTAssertEqual(saved, store.state)
        let history = try await database.history(accountID: account.id, since: .distantPast)
        XCTAssertTrue(history.isEmpty)
    }

    func testCancelledConnectionCannotCommitThroughTheMutationQueue() async throws {
        let database = try makeDatabase()
        let store = AppStore(database: database)
        await store.load()
        let account = ProviderAccount(provider: .codex, nickname: "Work", subject: "user", scope: "workspace")
        let snapshot = QuotaSnapshot(accountID: account.id, subject: account.subject, scope: account.scope, observedAt: .now, windows: [])
        let attempt = Task { try await store.acceptConnection(account, snapshot: snapshot, replacing: nil) }
        attempt.cancel()
        do {
            try await attempt.value
            XCTFail("A cancelled sign-in must leave no account")
        } catch is CancellationError {}
        let saved = try await database.load()
        XCTAssertTrue(saved.accounts.isEmpty)
        XCTAssertTrue(store.state.accounts.isEmpty)
    }

    func testRowAlarmSelectionHonorsTheLastRequestedValueAcrossQueuedWrites() async throws {
        let database = try makeDatabase()
        let store = AppStore(database: database)
        await store.load()

        store.setCapacityAlerts(false, account: "account", window: "weekly")
        store.setCapacityAlerts(false, account: "account", window: "weekly")
        await store.waitForPendingMutations()
        XCTAssertEqual(store.state.settings.disabledCapacityAlerts, [QuotaAlertSection(accountID: "account", windowID: "weekly")])

        store.setCapacityAlerts(true, account: "account", window: "weekly")
        store.setCapacityAlerts(false, account: "account", window: "weekly")
        store.setCapacityAlerts(true, account: "account", window: "weekly")
        await store.waitForPendingMutations()
        let saved = try await database.load()
        XCTAssertTrue(saved.settings.disabledCapacityAlerts.isEmpty)
        XCTAssertEqual(store.state, saved)
    }

    func testInvalidWindowThresholdsAndSettingsCannotMakeSavedStateUnreadable() async throws {
        let database = try makeDatabase()
        let store = AppStore(database: database)
        await store.load()
        let original = store.state
        store.setThresholds(account: "account", window: "weekly", thresholds: AlertThresholds(warning: 20, critical: 30, info: 50))
        await store.waitForPendingMutations()
        XCTAssertEqual(store.errorMessage, PreferenceError.invalidThresholds.localizedDescription)
        XCTAssertEqual(store.state, original)

        var invalid = original
        invalid.settings.historyRetentionDays = 0
        do {
            try await database.save(invalid)
            XCTFail("The storage boundary must reject preferences that cannot be reopened")
        } catch PreferenceError.invalidRange {}
        let saved = try await database.load()
        XCTAssertEqual(saved, original)
    }

    func testQueuedLoginItemChangeUsesTheActiveModeAfterEarlierWrites() async throws {
        let database = try makeDatabase()
        let store = AppStore(database: database)
        await store.load()
        let original = store.state
        store.enterDemo()
        store.setLaunchAtSignIn(false)
        await store.waitForPendingMutations()
        XCTAssertTrue(store.isDemo)
        XCTAssertFalse(store.state.settings.launchAtSignIn)
        let saved = try await database.load()
        XCTAssertEqual(saved, original)

        store.exitDemo()
        store.setLaunchAtSignIn(false)
        await store.waitForPendingMutations()
        XCTAssertFalse(store.isDemo)
        let afterExit = try await database.load()
        XCTAssertFalse(afterExit.settings.launchAtSignIn)
        XCTAssertEqual(afterExit, store.state)
    }
}

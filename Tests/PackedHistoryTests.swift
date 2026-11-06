import XCTest
import SQLite3
@testable import AITokenScrooge

final class PackedHistoryTests: XCTestCase {
    func testVersionOneHistoryLoadsAndConvertsWhenExtended() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("legacy.db")
        let now = Date(timeIntervalSince1970: 1800000000)
        let account = ProviderAccount(id: "legacy-account", provider: .codex, nickname: "A", subject: "s", scope: "w")
        var snapshot = QuotaSnapshot(accountID: account.id, subject: "s", scope: "w", observedAt: now, windows: [])
        let run = HistoryRun(id: "legacy-run", snapshot: snapshot, lastObservedAt: now, pollingMinutes: 2, revision: 1)
        let payload = try JSONEncoder().encode(run).map { String(format: "%02x", $0) }.joined()
        var connection: OpaquePointer?
        XCTAssertEqual(sqlite3_open(url.path, &connection), SQLITE_OK)
        defer { sqlite3_close(connection) }
        let schema = """
        CREATE TABLE history (id TEXT PRIMARY KEY, account TEXT NOT NULL, first REAL NOT NULL, last REAL NOT NULL, revision INTEGER NOT NULL, payload BLOB NOT NULL);
        CREATE TABLE history_clock (id INTEGER PRIMARY KEY CHECK(id=1), revision INTEGER NOT NULL);
        INSERT INTO history_clock VALUES(1,1);
        INSERT INTO history VALUES('legacy-run','legacy-account',1800000000,1800000000,1,X'\(payload)');
        PRAGMA user_version=1;
        """
        XCTAssertEqual(sqlite3_exec(connection, schema, nil, nil, nil), SQLITE_OK)
        let store = try LocalStore(url: url)
        let loaded = try await store.history(accountID: account.id, since: now)
        XCTAssertEqual(loaded, [run])
        snapshot.observedAt = now.addingTimeInterval(120)
        var state = PersistedState(); state.accounts = [account]
        try await store.accept(snapshot, account: account, state: state)
        let reopened = try LocalStore(url: url)
        let extended = try await reopened.history(accountID: account.id, since: now)
        XCTAssertEqual(extended.count, 1)
        XCTAssertEqual(extended.first?.count, 2)
        XCTAssertEqual(extended.first?.lastObservedAt, snapshot.observedAt)
        XCTAssertEqual(extended.first?.revision, 2)
        var query: OpaquePointer?
        XCTAssertEqual(sqlite3_prepare_v2(connection, "SELECT count(*) FROM history_metadata", -1, &query, nil), SQLITE_OK)
        defer { sqlite3_finalize(query) }
        XCTAssertEqual(sqlite3_step(query), SQLITE_ROW)
        XCTAssertEqual(sqlite3_column_int(query, 0), 1)
    }
    func testFailedSchemaUpgradeLeavesTheOriginalDatabaseIntact() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.db")
        var database: OpaquePointer?
        XCTAssertEqual(sqlite3_open(url.path, &database), SQLITE_OK)
        defer { sqlite3_close(database) }

        // An incompatible legacy history table makes index creation fail midway.
        XCTAssertEqual(sqlite3_exec(database, "CREATE TABLE history(legacy INTEGER); PRAGMA user_version=1", nil, nil, nil), SQLITE_OK)
        XCTAssertThrowsError(try LocalStore(url: url))
        var query: OpaquePointer?
        XCTAssertEqual(sqlite3_prepare_v2(database, "SELECT user_version, (SELECT count(*) FROM sqlite_schema WHERE name='state') FROM pragma_user_version", -1, &query, nil), SQLITE_OK)
        defer { sqlite3_finalize(query) }
        XCTAssertEqual(sqlite3_step(query), SQLITE_ROW)
        XCTAssertEqual(sqlite3_column_int(query, 0), 1)
        XCTAssertEqual(sqlite3_column_int(query, 1), 0)
    }

    func testRetentionFailureRollsBackStateAndHistoryTogether() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.db")
        let store = try LocalStore(url: url)
        let now = Date(timeIntervalSince1970: 1800000000)
        let account = ProviderAccount(provider: .codex, nickname: "A", subject: "s", scope: "w")
        let snapshot = QuotaSnapshot(accountID: account.id, subject: "s", scope: "w", observedAt: now.addingTimeInterval(-172800), windows: [])
        var original = PersistedState(); original.accounts = [account]
        original.alerts = [AlertEvent(id: "old", accountID: account.id, title: "Old", detail: "", createdAt: snapshot.observedAt)]
        try await store.accept(snapshot, account: account, state: original)
        var connection: OpaquePointer?
        XCTAssertEqual(sqlite3_open(url.path, &connection), SQLITE_OK)
        defer { sqlite3_close(connection) }
        XCTAssertEqual(sqlite3_exec(connection, "CREATE TRIGGER fail_prune BEFORE DELETE ON history BEGIN SELECT RAISE(ABORT, 'injected failure'); END", nil, nil, nil), SQLITE_OK)
        var candidate = original; candidate.alerts = []
        do { try await store.prune(now: now, days: 1, state: candidate); XCTFail("Expected injected delete failure") } catch {}
        let retained = try await store.load()
        let history = try await store.history(accountID: account.id, since: .distantPast)
        XCTAssertEqual(retained, original)
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(sqlite3_exec(connection, "DROP TRIGGER fail_prune", nil, nil, nil), SQLITE_OK)
        try await store.prune(now: now, days: 1, state: candidate)
        let pruned = try await store.load()
        let empty = try await store.history(accountID: account.id, since: .distantPast)
        XCTAssertEqual(pruned, candidate)
        XCTAssertTrue(empty.isEmpty)
    }
    func testPruningAndAccountRemovalKeepSurvivingMetadataReadable() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.db")
        let store = try LocalStore(url: url)
        let account = ProviderAccount(provider: .codex, nickname: "A", subject: "s", scope: "w")
        let now = Date(timeIntervalSince1970: 1800000000)
        var snapshot = QuotaSnapshot(accountID: account.id, subject: "s", scope: "w", observedAt: now.addingTimeInterval(-172800),
            windows: [QuotaWindow(id: "weekly", name: "Weekly", unit: .percent, used: 25, limit: 100)])
        var state = PersistedState(); state.accounts = [account]
        try await store.accept(snapshot, account: account, state: state)
        snapshot.observedAt = now; snapshot.windows[0].used = 30
        try await store.accept(snapshot, account: account, state: state)
        try await store.prune(now: now, days: 1)
        let reopened = try LocalStore(url: url)
        let remaining = try await reopened.history(accountID: account.id, since: .distantPast)
        XCTAssertEqual(remaining.map(\.snapshot), [snapshot])
        try await store.removeAccount(account.id, state: PersistedState())
        let removed = try await store.history(accountID: account.id, since: .distantPast)
        XCTAssertTrue(removed.isEmpty)
        try await store.accept(snapshot, account: account, state: state)
        let restored = try await store.history(accountID: account.id, since: .distantPast)
        XCTAssertEqual(restored.map(\.snapshot), [snapshot])
    }
    func testChangedUsageSharesMetadataWithoutLosingEndpoints() throws {
        let now = Date(timeIntervalSince1970: 1800000000)
        let snapshot = QuotaSnapshot(accountID: "a", subject: "s", scope: "w", observedAt: now,
            windows: [QuotaWindow(id: "weekly", name: "Weekly", unit: .percent, used: 25, limit: 100, resetsAt: now.addingTimeInterval(86400), durationMinutes: 10080)], planType: "Plus")
        let original = HistoryRun(snapshot: snapshot, lastObservedAt: now.addingTimeInterval(120), count: 2, pollingMinutes: 2, maximumGap: 120, revision: 7)
        var changed = original; changed.snapshot.windows[0].used = 30; changed.snapshot.observedAt = now.addingTimeInterval(240)
        changed.lastObservedAt = changed.snapshot.observedAt; changed.count = 1; changed.revision = 8
        let first = try PackedHistoryRun.pack(original), second = try PackedHistoryRun.pack(changed)
        XCTAssertEqual(first.record.metadataID, second.record.metadataID)
        let metadata = try JSONDecoder().decode(QuotaSnapshot.self, from: first.metadata)
        XCTAssertEqual(try first.record.unpack(metadata: metadata), original)
        XCTAssertEqual(try second.record.unpack(metadata: metadata), changed)
        changed.snapshot.planType = "Pro"
        XCTAssertNotEqual(try PackedHistoryRun.pack(changed).record.metadataID, first.record.metadataID)
    }
}

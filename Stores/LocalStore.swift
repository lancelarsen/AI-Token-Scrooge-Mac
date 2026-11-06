import Foundation
import SQLite3

enum StoreError: LocalizedError {
    case operation, newerSchema
    var errorDescription: String? { switch self {
    case .operation: "Your changes could not be saved. Please check available disk space and try again."
    case .newerSchema: "This data was created by a newer version of Scrooge. Please update the app."
    } }
}

/// Only LocalStore's actor accesses this connection. The wrapper owns deterministic cleanup.
private final class SQLiteConnection {
    let handle: OpaquePointer
    init(path: String) throws {
        var pointer: OpaquePointer?
        guard sqlite3_open_v2(path, &pointer, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK, let pointer else {
            if let pointer { sqlite3_close(pointer) }; throw StoreError.operation
        }
        handle = pointer
        sqlite3_busy_timeout(handle, 5000)
    }
    deinit { sqlite3_close(handle) }

    func prepare(_ sql: String) throws -> OpaquePointer {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK, let statement else { throw StoreError.operation }
        return statement
    }
    func execute(_ sql: String) throws {
        guard sqlite3_exec(handle, sql, nil, nil, nil) == SQLITE_OK else { throw StoreError.operation }
    }

    func transaction(_ body: () throws -> Void) throws {
        try execute("BEGIN IMMEDIATE")
        do {
            try body()
            try execute("COMMIT")
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }
}

actor LocalStore {
    private let connection: SQLiteConnection
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var metadataCache: [String: QuotaSnapshot] = [:]
    init(url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        connection = try SQLiteConnection(path: url.path)
        try Self.configure(connection)
    }

    private static func configure(_ connection: SQLiteConnection) throws {
        try connection.transaction {
            let version = try connection.prepare("PRAGMA user_version")
            defer { sqlite3_finalize(version) }
            guard sqlite3_step(version) == SQLITE_ROW else { throw StoreError.operation }
            guard sqlite3_column_int(version, 0) <= 2 else { throw StoreError.newerSchema }

            try connection.execute("""
            CREATE TABLE IF NOT EXISTS state (id INTEGER PRIMARY KEY CHECK(id=1), payload BLOB NOT NULL);
            CREATE TABLE IF NOT EXISTS history (id TEXT PRIMARY KEY, account TEXT NOT NULL, first REAL NOT NULL, last REAL NOT NULL, revision INTEGER NOT NULL, payload BLOB NOT NULL);
            CREATE INDEX IF NOT EXISTS history_range ON history(account, last);
            CREATE INDEX IF NOT EXISTS history_revision ON history(account, revision);
            CREATE TABLE IF NOT EXISTS history_clock (id INTEGER PRIMARY KEY CHECK(id=1), revision INTEGER NOT NULL);
            INSERT OR IGNORE INTO history_clock VALUES(1,0);
            CREATE TABLE IF NOT EXISTS history_metadata (id TEXT PRIMARY KEY, payload BLOB NOT NULL);
            PRAGMA user_version=2;
            """)
        }
        try connection.execute("PRAGMA journal_mode=WAL")
    }

    func load() throws -> PersistedState {
        let statement = try connection.prepare("SELECT payload FROM state WHERE id=1")
        defer { sqlite3_finalize(statement) }
        let result = sqlite3_step(statement)
        if result == SQLITE_DONE { return PersistedState() }
        guard result == SQLITE_ROW else { throw StoreError.operation }
        return try decoder.decode(PersistedState.self, from: blob(statement, column: 0))
    }
    func save(_ state: PersistedState) throws { try saveState(state) }
    func accept(_ snapshot: QuotaSnapshot, account: ProviderAccount, state: PersistedState) throws {
        guard snapshot.belongs(to: account) else { throw AccountError.differentIdentity }
        try connection.transaction {
            try saveState(state)
            try appendHistory(snapshot, polling: account.effectivePollingMinutes)
        }
    }
    func history(accountID: String, since: Date, until: Date = .distantFuture) throws -> [HistoryRun] {
        // Include the last preceding run as a continuity anchor without inventing observations.
        let statement = try connection.prepare("SELECT payload FROM history WHERE account=? AND first<=? AND (last>=? OR id=(SELECT id FROM history WHERE account=? AND last<? ORDER BY last DESC LIMIT 1)) ORDER BY first")
        defer { sqlite3_finalize(statement) }
        bind(accountID, to: statement, index: 1); sqlite3_bind_double(statement, 2, until.timeIntervalSince1970)
        sqlite3_bind_double(statement, 3, since.timeIntervalSince1970); bind(accountID, to: statement, index: 4)
        sqlite3_bind_double(statement, 5, since.timeIntervalSince1970)
        return try readHistory(statement)
    }

    func historyChanges(accountID: String, since: Date, afterRevision: Int64?) throws -> (runs: [HistoryRun], revision: Int64) {
        let clock = try connection.prepare("SELECT revision FROM history_clock WHERE id=1")
        defer { sqlite3_finalize(clock) }
        guard sqlite3_step(clock) == SQLITE_ROW else { throw StoreError.operation }
        let revision = sqlite3_column_int64(clock, 0)
        guard let afterRevision, afterRevision <= revision else { return (try history(accountID: accountID, since: since), revision) }
        let statement = try connection.prepare("SELECT payload FROM history WHERE account=? AND revision>? ORDER BY first")
        defer { sqlite3_finalize(statement) }
        bind(accountID, to: statement, index: 1); sqlite3_bind_int64(statement, 2, afterRevision)
        return (try readHistory(statement), revision)
    }

    private func readHistory(_ statement: OpaquePointer) throws -> [HistoryRun] {
        var changes: [HistoryRun] = []
        while true {
            let result = sqlite3_step(statement)
            if result == SQLITE_DONE { break }
            guard result == SQLITE_ROW else { throw StoreError.operation }
            changes.append(try decodeHistory(blob(statement, column: 0)))
        }
        return changes
    }
    func removeAccount(_ id: String, state: PersistedState) throws {
        try connection.transaction {
            try saveState(state)
            let statement = try connection.prepare("DELETE FROM history WHERE account=?")
            defer { sqlite3_finalize(statement) }; bind(id, to: statement, index: 1); try finish(statement)
            try collectUnusedMetadata()
        }
    }
    func prune(now: Date, days: Int, state: PersistedState? = nil) throws {
        try connection.transaction {
            if let state { try saveState(state) }
            let statement = try connection.prepare("DELETE FROM history WHERE last<?")
            defer { sqlite3_finalize(statement) }
            sqlite3_bind_double(statement, 1, now.addingTimeInterval(-Double(min(365, max(1, days))) * 86400).timeIntervalSince1970)
            try finish(statement)
            try collectUnusedMetadata()
        }
    }
    private func collectUnusedMetadata() throws {
        try connection.execute("DELETE FROM history_metadata WHERE id NOT IN (SELECT json_extract(CAST(payload AS TEXT),'$.metadataID') FROM history WHERE json_extract(CAST(payload AS TEXT),'$.metadataID') IS NOT NULL)")
        metadataCache.removeAll(keepingCapacity: true)
    }
    private func saveState(_ state: PersistedState) throws {
        try state.validate()
        let statement = try connection.prepare("INSERT INTO state(id,payload) VALUES(1,?) ON CONFLICT(id) DO UPDATE SET payload=excluded.payload")
        defer { sqlite3_finalize(statement) }; try bind(encoder.encode(state), to: statement, index: 1); try finish(statement)
    }
    private func appendHistory(_ snapshot: QuotaSnapshot, polling: Int) throws {
        let latest = try connection.prepare("SELECT payload FROM history WHERE account=? ORDER BY last DESC LIMIT 1")
        defer { sqlite3_finalize(latest) }
        bind(snapshot.accountID, to: latest, index: 1)
        let result = sqlite3_step(latest)
        var prior: HistoryRun?
        if result == SQLITE_ROW { prior = try decodeHistory(blob(latest, column: 0)) }
        guard result == SQLITE_ROW || result == SQLITE_DONE else { throw StoreError.operation }
        var run = HistoryRun(snapshot: snapshot, lastObservedAt: snapshot.observedAt, pollingMinutes: polling)
        if var previous = prior, previous.canExtend(with: snapshot, polling: polling) {
            previous.maximumGap = max(previous.maximumGap, snapshot.observedAt.timeIntervalSince(previous.lastObservedAt))
            previous.lastObservedAt = snapshot.observedAt; previous.count += 1; run = previous
        }
        try connection.execute("UPDATE history_clock SET revision=revision+1 WHERE id=1")
        let clock = try connection.prepare("SELECT revision FROM history_clock WHERE id=1")
        guard sqlite3_step(clock) == SQLITE_ROW else { sqlite3_finalize(clock); throw StoreError.operation }
        run.revision = sqlite3_column_int64(clock, 0); sqlite3_finalize(clock)
        let statement = try connection.prepare("INSERT OR REPLACE INTO history(id,account,first,last,revision,payload) VALUES(?,?,?,?,?,?)")
        defer { sqlite3_finalize(statement) }
        bind(run.id, to: statement, index: 1); bind(snapshot.accountID, to: statement, index: 2)
        sqlite3_bind_double(statement, 3, run.firstObservedAt.timeIntervalSince1970); sqlite3_bind_double(statement, 4, run.lastObservedAt.timeIntervalSince1970)
        sqlite3_bind_int64(statement, 5, run.revision); try bind(encodeHistory(run), to: statement, index: 6); try finish(statement)
    }
    private func encodeHistory(_ run: HistoryRun) throws -> Data {
        let packed = try PackedHistoryRun.pack(run)
        let statement = try connection.prepare("INSERT OR IGNORE INTO history_metadata(id,payload) VALUES(?,?)")
        defer { sqlite3_finalize(statement) }
        bind(packed.record.metadataID, to: statement, index: 1)
        try bind(packed.metadata, to: statement, index: 2); try finish(statement)
        return try encoder.encode(packed.record)
    }
    private func decodeHistory(_ data: Data) throws -> HistoryRun {
        // Existing version-one history remains readable and is packed when a run is extended.
        guard let packed = try? decoder.decode(PackedHistoryRun.self, from: data) else { return try decoder.decode(HistoryRun.self, from: data) }
        if let metadata = metadataCache[packed.metadataID] { return try packed.unpack(metadata: metadata) }
        let statement = try connection.prepare("SELECT payload FROM history_metadata WHERE id=?")
        defer { sqlite3_finalize(statement) }
        bind(packed.metadataID, to: statement, index: 1)
        guard sqlite3_step(statement) == SQLITE_ROW else { throw StoreError.operation }
        let metadata = try decoder.decode(QuotaSnapshot.self, from: blob(statement, column: 0))
        if metadataCache.count >= 512 { metadataCache.removeAll(keepingCapacity: true) }
        metadataCache[packed.metadataID] = metadata
        return try packed.unpack(metadata: metadata)
    }
    private func finish(_ statement: OpaquePointer) throws { guard sqlite3_step(statement) == SQLITE_DONE else { throw StoreError.operation } }
    private func bind(_ string: String, to statement: OpaquePointer, index: Int32) {
        _ = string.withCString { sqlite3_bind_text(statement, index, $0, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self)) }
    }
    private func bind(_ data: Data, to statement: OpaquePointer, index: Int32) throws {
        let result = data.withUnsafeBytes { sqlite3_bind_blob(statement, index, $0.baseAddress, Int32($0.count), unsafeBitCast(-1, to: sqlite3_destructor_type.self)) }
        guard result == SQLITE_OK else { throw StoreError.operation }
    }
    private func blob(_ statement: OpaquePointer, column: Int32) -> Data {
        guard let bytes = sqlite3_column_blob(statement, column) else { return Data() }
        return Data(bytes: bytes, count: Int(sqlite3_column_bytes(statement, column)))
    }
}

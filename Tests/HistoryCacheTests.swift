import XCTest
@testable import AITokenScrooge

final class HistoryCacheTests: XCTestCase {
    func testIncrementalReadReplacesExtendedRunAndEmptyDeltaPreservesIt() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try LocalStore(url: directory.appendingPathComponent("test.db"))
        let account = ProviderAccount(provider: .codex, nickname: "A", subject: "s", scope: "w")
        let now = Date(timeIntervalSince1970: 1800000000)
        var snapshot = QuotaSnapshot(accountID: account.id, subject: "s", scope: "w", observedAt: now, windows: [])
        var state = PersistedState(); state.accounts = [account]
        try await store.accept(snapshot, account: account, state: state)
        var cache = HistoryRunCache()
        let initial = try await store.historyChanges(accountID: account.id, since: now, afterRevision: nil)
        cache.merge(initial.runs, revision: initial.revision, since: now)
        snapshot.observedAt = now.addingTimeInterval(120)
        try await store.accept(snapshot, account: account, state: state)
        let delta = try await store.historyChanges(accountID: account.id, since: now, afterRevision: cache.revision)
        XCTAssertEqual(delta.runs.count, 1)
        cache.merge(delta.runs, revision: delta.revision, since: now)
        XCTAssertEqual(cache.runs.count, 1)
        XCTAssertEqual(cache.runs[0].count, 2)
        let unchanged = try await store.historyChanges(accountID: account.id, since: now, afterRevision: cache.revision)
        XCTAssertTrue(unchanged.runs.isEmpty)
        cache.merge(unchanged.runs, revision: unchanged.revision, since: now)
        XCTAssertEqual(cache.runs[0].lastObservedAt, snapshot.observedAt)
    }
}

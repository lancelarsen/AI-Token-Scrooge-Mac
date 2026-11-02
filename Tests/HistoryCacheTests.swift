import XCTest
@testable import AITokenScrooge

final class HistoryCacheTests: XCTestCase {
    func testExpandedCalendarRangeRequiresFullReload() {
        let zone = TimeZone(identifier: "America/Chicago")!
        let now = ISO8601DateFormatter().date(from: "2026-11-02T18:00:00Z")!
        let since = HorizonViewport(now: now, furthestFuture: nil, zone: zone, width: 700).date(at: 0)
        XCTAssertEqual(now.timeIntervalSince(since), 7 * 86400 + 3600, accuracy: 0.01)
        var cache = HistoryRunCache()
        XCTAssertFalse(cache.covers(since: since))
        cache.merge([], revision: 1, since: now.addingTimeInterval(-7 * 86400))
        XCTAssertFalse(cache.covers(since: since))
        cache.merge([], revision: 2, since: since)
        XCTAssertTrue(cache.covers(since: since.addingTimeInterval(60)))
    }
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

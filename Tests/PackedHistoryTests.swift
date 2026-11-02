import XCTest
@testable import AITokenScrooge

final class PackedHistoryTests: XCTestCase {
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

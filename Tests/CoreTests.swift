import XCTest
@testable import AITokenScrooge

final class CoreTests: XCTestCase {
    func testCodexProtocolExcludesInferenceAndRedemption() {
        XCTAssertEqual(CodexConnection.allowed, ["initialize", "account/read", "account/rateLimits/read", "account/login/start", "account/login/cancel", "account/logout"])
        XCTAssertFalse(CodexConnection.allowed.contains("thread/start"))
        XCTAssertFalse(CodexConnection.allowed.contains("turn/start"))
    }
    func testInstalledCodexStartsWithIsolatedSignedOutProfile() async throws {
        guard (try? CodexConnection.executable()) != nil else { throw XCTSkip("Codex CLI is not installed on this test host.") }
        let id = UUID().uuidString
        let profile = try CodexConnection.profileURL(id: id)
        defer { try? FileManager.default.removeItem(at: profile) }
        let connection = try await CodexConnection.start(credentialID: id)
        do {
            let identity = try await connection.call("account/read", parameters: .object(["refreshToken": .bool(false)]))
            XCTAssertNil(identity["account"]["email"].string, "A fresh profile must not inherit the user's normal Codex login.")
            await connection.close()
        } catch { await connection.close(); throw error }
    }
    func testUnknownAndOverageAreDistinct() {
        let unknown = QuotaWindow(id: "q", name: "q", unit: .credits, used: 10)
        XCTAssertNil(unknown.remainingPercent)
        XCTAssertEqual(unknown.capacity(), .unknown)
        let overage = QuotaWindow(id: "q", name: "q", unit: .credits, used: 120, limit: 100)
        XCTAssertEqual(overage.remaining, -20)
        XCTAssertEqual(overage.remainingPercent, 0)
        XCTAssertEqual(overage.capacity(), .exhausted)
    }
    func testBillingUnknownUnitsDoNotBecomeZero() throws {
        let account = ProviderAccount(provider: .copilot, nickname: "Test", subject: "1", scope: "personal")
        let response = try JSONDecoder().decode(JSONValue.self, from: Data(#"{"usageItems":[{"unitType":"future-unit","grossQuantity":20}]}"#.utf8))
        let snapshot = try ProviderMapping.github(account: account, response: response, observed: .now)
        XCTAssertNil(snapshot.windows.first?.used)
    }
    func testCodexRejectsDifferentWorkspace() throws {
        let account = ProviderAccount(provider: .codex, nickname: "Test", subject: "a@example.test", scope: "original")
        let response = JSONValue.object(["accountId": .string("different")])
        XCTAssertThrowsError(try ProviderMapping.codex(account: account, response: response, observed: .now))
    }
    func testReserveOnlyIsHealthyWithoutInventedWindows() throws {
        let account = ProviderAccount(provider: .codex, nickname: "Test", subject: "a@example.test", scope: "scope")
        let response = try JSONDecoder().decode(JSONValue.self, from: Data(#"{"accountId":"scope","rateLimitResetCredits":{"availableCount":3}}"#.utf8))
        let snapshot = try ProviderMapping.codex(account: account, response: response, observed: .now)
        XCTAssertEqual(snapshot.health, .healthy)
        XCTAssertTrue(snapshot.windows.isEmpty)
        XCTAssertEqual(snapshot.reserve?.availableCount, 3)
        XCTAssertTrue(snapshot.reserve?.hasPartialDetails == true)
    }
    func testDSTDaysKeepEqualWidthsAndRepeatedHoursDistinct() throws {
        let zone = try XCTUnwrap(TimeZone(identifier: "America/Chicago"))
        let parser = ISO8601DateFormatter()
        let start = try XCTUnwrap(parser.date(from: "2026-11-01T05:00:00Z"))
        let next = start.addingTimeInterval(25 * 3600)
        let viewport = HorizonViewport(now: start, furthestFuture: next.addingTimeInterval(86400), zone: zone, width: 600)
        XCTAssertEqual(viewport.position(at: next) - viewport.position(at: start), viewport.pixelsPerDay, accuracy: 0.00001)
        let first = start.addingTimeInterval(5400)
        let second = first.addingTimeInterval(3600)
        XCTAssertGreaterThan(viewport.position(at: second), viewport.position(at: first))
        XCTAssertEqual(viewport.date(at: viewport.position(at: second)).timeIntervalSince(second), 0, accuracy: 0.001)
    }
    func testPersistenceCompactsOnlyCompatibleObservations() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try LocalStore(url: directory.appendingPathComponent("test.db"))
        let account = ProviderAccount(provider: .codex, nickname: "Test", subject: "a", scope: "s")
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var snapshot = QuotaSnapshot(accountID: account.id, subject: account.subject, scope: account.scope, observedAt: now, windows: [])
        var state = PersistedState(); state.accounts = [account]; state.snapshots[account.id] = snapshot
        try await store.accept(snapshot, account: account, state: state)
        snapshot.observedAt = now.addingTimeInterval(120); state.snapshots[account.id] = snapshot
        try await store.accept(snapshot, account: account, state: state)
        let compact = try await store.history(accountID: account.id, since: now)
        XCTAssertEqual(compact.count, 1)
        XCTAssertEqual(compact.first?.count, 2)
        snapshot.observedAt = now.addingTimeInterval(3600); state.snapshots[account.id] = snapshot
        try await store.accept(snapshot, account: account, state: state)
        let separated = try await store.history(accountID: account.id, since: now)
        XCTAssertEqual(separated.count, 2)
        let loaded = try await store.load()
        XCTAssertEqual(loaded, state)
    }
}

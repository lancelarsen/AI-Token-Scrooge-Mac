import XCTest
@testable import AITokenScrooge

final class CoreTests: XCTestCase {
    func testFreshnessUsesSelectedZoneAndDaySuffix() {
        let date = ISO8601DateFormatter().date(from: "2026-11-02T18:00:00Z")!
        XCTAssertEqual(Format.updated(date, zone: TimeZone(identifier: "America/Chicago")!), "Updated 12:00 PM CST\nMonday, Nov 2nd")
        let eleventh = ISO8601DateFormatter().date(from: "2026-11-11T18:00:00Z")!
        XCTAssertTrue(Format.updated(eleventh, zone: TimeZone(secondsFromGMT: 0)!).hasSuffix("Nov 11th"))
    }
    func testProviderUsageLinksKeepOrganizationAsEscapedPathComponent() {
        var account = ProviderAccount(provider: .copilot, nickname: "A", subject: "s", scope: "personal")
        XCTAssertEqual(account.usageURL?.absoluteString, "https://github.com/settings/billing")
        account.scope = "ORGANIZATION:team/name?query#fragment"
        XCTAssertEqual(account.usageURL?.absoluteString, "https://github.com/organizations/team%2Fname%3Fquery%23fragment/settings/billing")
        XCTAssertEqual(account.usageURL?.host, "github.com")
        account.provider = .claude
        XCTAssertEqual(account.usageURL?.absoluteString, "https://claude.ai/new#settings/usage")
        account.provider = .codex
        XCTAssertEqual(account.usageURL?.absoluteString, "https://chatgpt.com/settings/usage?tab=overview")
    }
    func testFirstCustomSortCapturesVisibleOrderAndLaterRestoresSavedOrder() {
        var state = DemoData.make(now: Date(timeIntervalSince1970: 1800000000)).0
        state.settings.accountOrder = ["removed-account"]
        state.settings.accountSort = .leastRemaining
        let visible = AccountPolicy.ordered(state).map(\.id)
        AccountPolicy.selectSort(.custom, state: &state)
        XCTAssertEqual(state.settings.accountOrder, visible)
        AccountPolicy.selectSort(.mostRemaining, state: &state)
        XCTAssertEqual(AccountPolicy.ordered(state, mode: .custom).map(\.id), visible)
        AccountPolicy.selectSort(.custom, state: &state)
        XCTAssertEqual(AccountPolicy.ordered(state).map(\.id), visible)
    }
    func testSortPlacesUnknownAndPausedAccountsLastAndKeepsTiesStable() {
        let now = Date(timeIntervalSince1970: 1800000000)
        var state = PersistedState()
        state.accounts = (0..<4).map { ProviderAccount(id: "a\($0)", provider: .codex, nickname: "A", subject: "s", scope: "w") }
        for index in 1..<4 {
            let account = state.accounts[index]
            state.snapshots[account.id] = QuotaSnapshot(accountID: account.id, subject: "s", scope: "w", observedAt: now,
                windows: [QuotaWindow(id: "q", name: "q", unit: .percent, used: 20, resetsAt: now)])
        }
        state.accounts[1].enabled = false
        for mode in [AccountSort.mostRemaining, .leastRemaining, .nextReset] {
            state.settings.accountSort = mode
            XCTAssertEqual(AccountPolicy.ordered(state).map(\.id), ["a2", "a3", "a0", "a1"])
        }
        state.settings.accountSort = .custom
        state.settings.accountOrder = ["removed", "a3", "a3"]
        XCTAssertEqual(AccountPolicy.ordered(state).map(\.id), ["a3", "a0", "a1", "a2"])
    }
    func testProviderPlanLabelsMatchSourceAndDoNotInventUnknownPlans() {
        XCTAssertEqual(Format.plan(.copilot, "individual_pro"), "Pro+")
        XCTAssertEqual(Format.plan(.copilot, "individual_max"), "Max")
        XCTAssertEqual(Format.plan(.copilot, "individual_edu"), "Education")
        XCTAssertEqual(Format.plan(.codex, "prolite"), "Pro Lite")
        XCTAssertEqual(Format.plan(.codex, "promax"), "Pro Max")
        XCTAssertEqual(Format.plan(.claude, "team"), "Team")
        XCTAssertEqual(Format.plan(.claude, "individual_max"), "Plan unavailable")
        XCTAssertEqual(Format.plan(.codex, nil), "Plan unavailable")
    }
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

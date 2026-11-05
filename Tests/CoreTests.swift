import XCTest
@testable import AITokenScrooge

final class CoreTests: XCTestCase {
    func testAccountDropCanReachBothEndsAndRejectInvalidMoves() {
        var state = PersistedState()
        state.accounts = ["a", "b", "c", "d"].map {
            ProviderAccount(id: $0, provider: .codex, nickname: $0, subject: $0, scope: "scope")
        }
        state.settings.accountSort = .custom
        AccountPolicy.reorder("a", relativeTo: "d", after: true, state: &state)
        XCTAssertEqual(AccountPolicy.ordered(state).map(\.id), ["b", "c", "d", "a"])
        AccountPolicy.reorder("a", relativeTo: "b", after: false, state: &state)
        XCTAssertEqual(AccountPolicy.ordered(state).map(\.id), ["a", "b", "c", "d"])
        AccountPolicy.reorder("b", relativeTo: "c", after: true, state: &state)
        XCTAssertEqual(AccountPolicy.ordered(state).map(\.id), ["a", "c", "b", "d"])
        let saved = state.settings.accountOrder
        AccountPolicy.reorder("b", relativeTo: "b", after: true, state: &state)
        AccountPolicy.reorder("missing", relativeTo: "a", after: true, state: &state)
        AccountPolicy.reorder("a", relativeTo: "missing", after: false, state: &state)
        XCTAssertEqual(state.settings.accountOrder, saved)
        state.settings.accountSort = .mostRemaining
        AccountPolicy.reorder("a", relativeTo: "d", after: true, state: &state)
        XCTAssertEqual(state.settings.accountOrder, saved)
    }

    func testSimultaneousTimelineEventsFollowWindowsOrdering() {
        let now = Date(timeIntervalSince1970: 1800000000)
        let tied = now.addingTimeInterval(3600)
        var state = PersistedState()
        state.accounts = ["a", "b"].map {
            ProviderAccount(id: $0, provider: .codex, nickname: $0, subject: $0, scope: "scope")
        }
        state.settings.accountSort = .custom
        state.settings.accountOrder = ["b", "a"]
        for account in state.accounts {
            state.snapshots[account.id] = QuotaSnapshot(accountID: account.id, subject: account.subject,
                scope: account.scope, observedAt: now,
                windows: [QuotaWindow(id: "first", name: "First", unit: .percent, resetsAt: tied),
                          QuotaWindow(id: "second", name: "Second", unit: .percent, resetsAt: tied)],
                reserve: ResetReserve(availableCount: 1, credits: [ResetCredit(id: "expiry", status: "available", expiresAt: tied)]))
        }
        XCTAssertEqual(HorizonEvent.events(state: state, now: now).map(\.id),
                       ["b/first", "b/second", "a/first", "a/second", "a/expiry", "b/expiry"])
        state.snapshots["a"]!.reserve!.credits![0].expiresAt = now.addingTimeInterval(60)
        XCTAssertEqual(HorizonEvent.events(state: state, now: now).first?.id, "a/expiry")
        state.settings.hiddenHistoryAccounts = ["b"]
        XCTAssertEqual(HorizonEvent.events(state: state, now: now).map(\.id), ["a/expiry", "a/first", "a/second"])
        state.accounts[0].enabled = false
        XCTAssertTrue(HorizonEvent.events(state: state, now: now).isEmpty)
    }

    func testCountAllowanceLabelsAndCopilotPercentException() {
        let window = QuotaWindow(id: "requests", name: "Requests", unit: .requests, used: 1250, limit: 1000)
        let labels = Format.usageText(window, provider: .claude, locale: Locale(identifier: "en_US"))
        XCTAssertEqual(labels.used, "1,250 used")
        XCTAssertEqual(labels.left, "250 over")
        let copilot = Format.usageText(window, provider: .copilot)
        XCTAssertEqual(copilot.used, "125% used")
        XCTAssertEqual(copilot.left, "0% left")
        let unknown = QuotaWindow(id: "requests", name: "Requests", unit: .requests)
        XCTAssertEqual(Format.usageText(unknown, provider: .claude).used, "Usage unavailable")
        XCTAssertEqual(Format.usageText(unknown, provider: .claude).left, "Limit unavailable")
    }

    func testFractionalThresholdBoundariesMatchWindows() {
        var thresholds = AlertThresholds(warning: 30.5, critical: 10.5, info: 50)
        thresholds.move(.warning, to: 0)
        XCTAssertEqual(thresholds.warning, 11)
        thresholds = AlertThresholds(warning: 30.5, critical: 10.5, info: 50)
        thresholds.move(.critical, to: 100)
        XCTAssertEqual(thresholds.critical, 30)
        thresholds.move(.info, to: 50.5)
        XCTAssertEqual(thresholds.info, 50)
        XCTAssertEqual(AlertThresholds.remaining(at: 49.5, width: 100), 51)
        XCTAssertEqual(AlertThresholds.remaining(at: .infinity, width: 100), 0)
        XCTAssertEqual(AlertThresholds.remaining(at: 10, width: 0), 0)
        XCTAssertTrue(thresholds.isValid)
    }

    func testColorPickerChannelStopsAtBoundaryBeforeWrapping() {
        XCTAssertEqual(ColorPickerChannel.stepped(0.4, maximum: 100, increasing: false, wraps: true), 0)
        XCTAssertEqual(ColorPickerChannel.stepped(0, maximum: 100, increasing: false, wraps: true), 100)
        XCTAssertEqual(ColorPickerChannel.stepped(99.6, maximum: 100, increasing: true, wraps: true), 100)
        XCTAssertEqual(ColorPickerChannel.stepped(100, maximum: 100, increasing: true, wraps: true), 0)
        XCTAssertEqual(ColorPickerChannel.stepped(360, maximum: 360, increasing: true, wraps: true), 0)
        XCTAssertEqual(ColorPickerChannel.stepped(100, maximum: 100, increasing: true, wraps: false), 100)
        XCTAssertEqual(ColorPickerChannel.stepped(0, maximum: 100, increasing: false, wraps: false), 0)
    }

    func testSpectrumSelectionContrastsWithDisplayedHueAndSaturation() {
        XCTAssertTrue(SpectrumSelectionContrast.usesLightStroke(hue: 0, saturation: 1))
        XCTAssertFalse(SpectrumSelectionContrast.usesLightStroke(hue: 1 / 3, saturation: 1))
        XCTAssertTrue(SpectrumSelectionContrast.usesLightStroke(hue: 2 / 3, saturation: 1))
        XCTAssertFalse(SpectrumSelectionContrast.usesLightStroke(hue: 0, saturation: 0))
        XCTAssertEqual(SpectrumSelectionContrast.usesLightStroke(hue: 0, saturation: 1),
                       SpectrumSelectionContrast.usesLightStroke(hue: 1, saturation: 1))
    }

    func testReferenceDateRequiresDemoAndValidTimestamp() {
        let stamp = "2026-11-04T16:11:00Z"
        let expected = ISO8601DateFormatter().date(from: stamp)!
        XCTAssertEqual(DemoData.referenceDate(arguments: ["app", "--demo", "--reference-date", stamp]), expected)
        XCTAssertNil(DemoData.referenceDate(arguments: ["app", "--reference-date", stamp]))
        XCTAssertNil(DemoData.referenceDate(arguments: ["app", "--demo", "--reference-date"]))
        XCTAssertNil(DemoData.referenceDate(arguments: ["app", "--demo", "--reference-date", "invalid"]))
        XCTAssertNil(DemoData.referenceDate(arguments: ["app", "--demo"]))
        let (state, history) = DemoData.make(now: expected)
        XCTAssertTrue(state.snapshots.values.allSatisfy { $0.observedAt == expected })
        XCTAssertTrue(history.allSatisfy { $0.lastObservedAt <= expected && $0.snapshot.observedAt <= expected })
    }

    func testDemoScenariosPreserveStandardValuesAndRepresentMissingData() {
        let now = Date(timeIntervalSince1970: 1793808000)
        let standard = DemoData.make(now: now).0
        let offline = DemoData.make(now: now, scenario: .offline).0
        for (id, snapshot) in standard.snapshots {
            XCTAssertEqual(snapshot.health, .demo)
            XCTAssertEqual(offline.snapshots[id]?.health, .offline)
            XCTAssertEqual(offline.snapshots[id]?.windows, snapshot.windows)
        }
        for snapshot in DemoData.make(now: now, scenario: .unknown).0.snapshots.values {
            XCTAssertTrue(snapshot.windows.allSatisfy { $0.used == nil && $0.limit == nil && $0.remainingPercent == nil })
        }
        for snapshot in DemoData.make(now: now, scenario: .noReset).0.snapshots.values {
            XCTAssertTrue(snapshot.windows.allSatisfy { $0.resetsAt == nil })
        }
        for snapshot in DemoData.make(now: now, scenario: .exhausted).0.snapshots.values {
            XCTAssertTrue(snapshot.windows.allSatisfy { $0.remainingPercent == 0 })
        }
        XCTAssertTrue(standard.snapshots.values.allSatisfy { $0.health == .demo && !$0.windows.isEmpty })
    }

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
        XCTAssertEqual(Format.historyPlanBadge(.codex, nil), "Weekly")
        XCTAssertEqual(Format.historyPlanBadge(.claude, "unrecognized"), "Weekly")
        XCTAssertEqual(Format.historyPlanBadge(.copilot, nil), "Monthly")
        XCTAssertEqual(Format.historyPlanBadge(.copilot, "individual_pro"), "Pro+")
        XCTAssertEqual(Format.historyPlanBadge(.codex, "plus"), "Plus")
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

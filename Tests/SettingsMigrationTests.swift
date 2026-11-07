import XCTest
@testable import AITokenScrooge

final class SettingsMigrationTests: XCTestCase {
    func testQuietHoursDraftRetainsSavedIntervalUntilValidAndPreservesOtherSettings() {
        var saved = RadarSettings()
        var draft = QuietHoursDraft(settings: saved)
        draft.end = draft.start
        let original = saved
        XCTAssertFalse(draft.apply(to: &saved))
        XCTAssertEqual(saved, original, "An enabled zero-length draft must not replace saved settings")
        saved.soundVolume = 27
        draft.start = 22
        draft.end = 6
        XCTAssertTrue(draft.apply(to: &saved))
        XCTAssertTrue(saved.quietHours)
        XCTAssertEqual(saved.quietStartHour, 22)
        XCTAssertEqual(saved.quietEndHour, 6)
        XCTAssertEqual(saved.soundVolume, 27, "Applying the recovered interval must retain unrelated edits")
        draft.enabled = false
        draft.end = draft.start
        XCTAssertTrue(draft.apply(to: &saved), "Disabled quiet hours may retain equal endpoints")
        XCTAssertFalse(saved.quietHours)
        draft.enabled = true
        XCTAssertFalse(draft.apply(to: &saved), "Re-enabling requires a nonempty interval")
        XCTAssertFalse(saved.quietHours)
    }

    func testQuietHoursDraftAcceptsEveryNonemptyDayOrOvernightInterval() throws {
        for enabled in [false, true] {
            for start in 0..<24 {
                for end in 0..<24 {
                    var draft = QuietHoursDraft(settings: RadarSettings())
                    draft.enabled = enabled; draft.start = start; draft.end = end
                    XCTAssertEqual(draft.isValid, !enabled || start != end)
                }
            }
        }
        // Existing files written by older Mac builds remain loadable; the
        // settings screen exposes their invalid interval as a recoverable draft.
        let legacy = try JSONDecoder().decode(RadarSettings.self,
            from: Data(#"{"quietHours":true,"quietStartHour":8,"quietEndHour":8}"#.utf8))
        XCTAssertFalse(QuietHoursDraft(settings: legacy).isValid)
    }

    func testAccountColorDefaultsFollowProviderAndPlanWithoutOverwritingCustomChoice() throws {
        var account = ProviderAccount(provider: .codex, nickname: "A", subject: "s", scope: "w")
        XCTAssertEqual(account.resolvedLineColor(plan: "ChatGPT Plus"), "#D587A5")
        XCTAssertEqual(account.resolvedLineColor(plan: "Pro"), "#B99AF8")
        account.provider = .copilot
        XCTAssertEqual(account.resolvedLineColor(plan: nil), "#CDEB82")
        account.provider = .claude
        XCTAssertEqual(account.resolvedLineColor(plan: nil), "#58A6FF")
        account.lineColor = "#123ABC"
        let restored = try JSONDecoder().decode(ProviderAccount.self, from: JSONEncoder().encode(account))
        XCTAssertEqual(restored.resolvedLineColor(plan: "Pro"), "#123ABC")
        account.lineColor = "invalid"
        XCTAssertEqual(account.resolvedLineColor(plan: nil), "#58A6FF")
    }
    func testMissingPreferencesUseSourceDefaults() throws {
        let settings = try JSONDecoder().decode(RadarSettings.self, from: Data(#"{"sound":true}"#.utf8))
        XCTAssertTrue(settings.sound)
        XCTAssertTrue(settings.notifications)
        XCTAssertEqual(settings.historyRetentionDays, 90)
        XCTAssertEqual(settings.timeZoneID, "America/Chicago")
        XCTAssertEqual(settings.thresholds, AlertThresholds())
    }
    func testNewDefaultsPreserveExplicitOlderPreferences() throws {
        let fresh = try JSONDecoder().decode(RadarSettings.self, from: Data("{}".utf8))
        XCTAssertTrue(fresh.sound)
        XCTAssertTrue(fresh.quietHours)
        XCTAssertEqual(fresh.quietStartHour, 0)
        XCTAssertEqual(fresh.quietEndHour, 8)
        XCTAssertEqual(fresh.accountSort, .custom)
        let saved = try JSONDecoder().decode(RadarSettings.self, from: Data(#"{"sound":false,"quietHours":false,"quietStartHour":22,"accountSort":"Next Reset"}"#.utf8))
        XCTAssertFalse(saved.sound)
        XCTAssertFalse(saved.quietHours)
        XCTAssertEqual(saved.quietStartHour, 22)
        XCTAssertEqual(saved.accountSort, .nextReset)
    }
    func testInvalidSavedThresholdsAreRejected() {
        XCTAssertThrowsError(try JSONDecoder().decode(RadarSettings.self, from: Data(#"{"thresholds":{"critical":60,"warning":30,"info":50}}"#.utf8)))
    }
    func testPartialNestedPreferencesPreserveSavedValuesAndDefaultNewFields() throws {
        let data = Data(#"{"thresholds":{"warning":35},"rules":[{"accountID":"a","low":false,"thresholds":{"critical":5}}]}"#.utf8)
        let settings = try JSONDecoder().decode(RadarSettings.self, from: data)
        XCTAssertEqual(settings.thresholds.warning, 35)
        XCTAssertEqual(settings.thresholds.critical, 10)
        XCTAssertEqual(settings.thresholds.info, 50)
        XCTAssertFalse(settings.rules[0].low)
        XCTAssertTrue(settings.rules[0].info)
        XCTAssertTrue(settings.rules[0].restored)
        XCTAssertEqual(settings.rules[0].thresholds?.critical, 5)
        XCTAssertEqual(try JSONDecoder().decode(RadarSettings.self, from: JSONEncoder().encode(settings)), settings)
    }
    func testMalformedNestedValuesAndMissingRuleIdentityRemainErrors() {
        for json in [#"{"thresholds":{"info":"invalid"}}"#, #"{"rules":[{"low":false}]}"#] {
            XCTAssertThrowsError(try JSONDecoder().decode(RadarSettings.self, from: Data(json.utf8)))
        }
    }
    func testOlderStateCanLoadAndRetirementRecordsRoundTrip() throws {
        var state = try JSONDecoder().decode(PersistedState.self, from: Data("{}".utf8))
        XCTAssertTrue(state.retiredAccounts.isEmpty)
        state.retiredAccounts = [ProviderAccount(provider: .codex, nickname: "Old", subject: "s", scope: "w")]
        let restored = try JSONDecoder().decode(PersistedState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(restored, state)
    }
    func testDuplicateAccountIDsFailBeforeUsageCanBeAssignedToTheWrongAccount() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let database = try LocalStore(url: directory.appendingPathComponent("test.db"))
        let account = ProviderAccount(provider: .codex, nickname: "Work", subject: "user", scope: "work")
        var otherWorkspace = account
        otherWorkspace.scope = "personal"
        var original = PersistedState()
        original.accounts = [account]
        try await database.save(original)
        var ambiguous = original
        ambiguous.accounts.append(otherWorkspace)
        XCTAssertThrowsError(try JSONDecoder().decode(PersistedState.self, from: JSONEncoder().encode(ambiguous)))
        do {
            try await database.save(ambiguous)
            XCTFail("Expected duplicate account IDs to be rejected")
        } catch AccountError.duplicateID {}
        let saved = try await database.load()
        XCTAssertEqual(saved, original)
    }

    func testSavedSnapshotForWrongIdentityIsDiscarded() throws {
        var state = PersistedState()
        let account = ProviderAccount(provider: .codex, nickname: "A", subject: "correct", scope: "w")
        state.accounts = [account]
        state.snapshots[account.id] = QuotaSnapshot(accountID: account.id, subject: "wrong", scope: "w", observedAt: .now, windows: [])
        let loaded = try JSONDecoder().decode(PersistedState.self, from: JSONEncoder().encode(state))
        XCTAssertTrue(loaded.snapshots.isEmpty)
    }
    func testUnknownSavedTimeZoneUsesSourceFallbackForQuietHours() throws {
        let settings = try JSONDecoder().decode(RadarSettings.self,
            from: Data(#"{"timeZoneID":"No/Such_Zone","quietHours":true,"quietStartHour":22,"quietEndHour":8}"#.utf8))
        XCTAssertEqual(settings.zone.identifier, "America/Chicago")
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-11-02T05:00:00Z"))
        XCTAssertTrue(settings.isQuiet(at: date))
        var utc = settings; utc.timeZoneID = "UTC"
        XCTAssertEqual(utc.zone.secondsFromGMT(for: date), 0)
    }

}

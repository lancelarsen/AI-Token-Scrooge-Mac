import XCTest
@testable import AITokenScrooge

final class SettingsMigrationTests: XCTestCase {
    func testMissingPreferencesUseSourceDefaults() throws {
        let settings = try JSONDecoder().decode(RadarSettings.self, from: Data(#"{"sound":true}"#.utf8))
        XCTAssertTrue(settings.sound)
        XCTAssertTrue(settings.notifications)
        XCTAssertEqual(settings.historyRetentionDays, 90)
        XCTAssertEqual(settings.timeZoneID, "America/Chicago")
        XCTAssertEqual(settings.thresholds, AlertThresholds())
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
    func testSavedSnapshotForWrongIdentityIsDiscarded() throws {
        var state = PersistedState()
        let account = ProviderAccount(provider: .codex, nickname: "A", subject: "correct", scope: "w")
        state.accounts = [account]
        state.snapshots[account.id] = QuotaSnapshot(accountID: account.id, subject: "wrong", scope: "w", observedAt: .now, windows: [])
        let loaded = try JSONDecoder().decode(PersistedState.self, from: JSONEncoder().encode(state))
        XCTAssertTrue(loaded.snapshots.isEmpty)
    }
}

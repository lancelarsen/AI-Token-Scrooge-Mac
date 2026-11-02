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

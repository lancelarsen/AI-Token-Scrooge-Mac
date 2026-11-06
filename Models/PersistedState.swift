import Foundation

struct PersistedState: Codable, Equatable, Sendable {
    var accounts: [ProviderAccount] = []
    var snapshots: [String: QuotaSnapshot] = [:]
    var settings = RadarSettings()
    var alerts: [AlertEvent] = []
    var snoozedAccounts: [String: Date] = [:]
    var retiredCredentialIDs: [String] = []
    var retiredAccounts: [ProviderAccount] = []
    init() {}
    func validate() throws {
        try settings.validate()
        guard Set(accounts.map(\.id)).count == accounts.count else { throw AccountError.duplicateID }
    }

    private enum CodingKeys: String, CodingKey { case accounts, snapshots, settings, alerts, snoozedAccounts, retiredCredentialIDs, retiredAccounts }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        accounts = try c.decodeIfPresent([ProviderAccount].self, forKey: .accounts) ?? []
        snapshots = try c.decodeIfPresent([String: QuotaSnapshot].self, forKey: .snapshots) ?? [:]
        settings = try c.decodeIfPresent(RadarSettings.self, forKey: .settings) ?? RadarSettings()
        alerts = try c.decodeIfPresent([AlertEvent].self, forKey: .alerts) ?? []
        snoozedAccounts = try c.decodeIfPresent([String: Date].self, forKey: .snoozedAccounts) ?? [:]
        if !c.contains(.snoozedAccounts) {
            for alert in alerts {
                if let until = alert.snoozedUntil {
                    snoozedAccounts[alert.accountID] = max(snoozedAccounts[alert.accountID] ?? .distantPast, until)
                }
            }
        }
        retiredCredentialIDs = try c.decodeIfPresent([String].self, forKey: .retiredCredentialIDs) ?? []
        retiredAccounts = try c.decodeIfPresent([ProviderAccount].self, forKey: .retiredAccounts) ?? []
        try validate()
        // Never attach saved usage to a different account or workspace.
        snapshots = snapshots.filter { key, snapshot in accounts.contains { $0.id == key && snapshot.belongs(to: $0) } }
    }
}

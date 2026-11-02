import Foundation

struct HorizonEvent: Identifiable, Sendable {
    var id: String
    var account: ProviderAccount
    var date: Date
    var expiration: Bool
    var title: String
    var plan: String?
    var reportedAt: Date? = nil
    static func events(state: PersistedState, now: Date) -> [Self] {
        state.accounts.filter { $0.enabled && !state.settings.hiddenHistoryAccounts.contains($0.id) }.flatMap { account -> [Self] in
            guard let snapshot = state.snapshots[account.id], snapshot.belongs(to: account) else { return [] }
            var events = snapshot.windows.compactMap { window -> Self? in
                guard let date = window.resetsAt, date > now else { return nil }
                return Self(id: "\(account.id)/\(window.id)", account: account, date: date, expiration: false, title: window.name, plan: snapshot.planType)
            }
            if snapshot.reserve?.availableCount != 0 {
                events += (snapshot.reserve?.credits ?? []).compactMap { credit -> Self? in
                    guard credit.status == "available", let date = credit.expiresAt, date > now else { return nil }
                    return Self(id: "\(account.id)/\(credit.id)", account: account, date: date, expiration: true, title: credit.title ?? "Earned Reset Expires", plan: snapshot.planType)
                }
            }
            return events
        }.sorted { $0.date < $1.date }
    }
}

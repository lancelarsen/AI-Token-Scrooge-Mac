import Foundation

struct HorizonEvent: Identifiable, Sendable {
    var id: String
    var account: ProviderAccount
    var date: Date
    var expiration: Bool
    var title: String
    var plan: String?
    var reportedAt: Date? = nil
    var windowID: String? = nil
    static func events(state: PersistedState, now: Date) -> [Self] {
        state.accounts.filter { $0.enabled && !state.settings.hiddenHistoryAccounts.contains($0.id) }.flatMap { account -> [Self] in
            guard let snapshot = state.snapshots[account.id], snapshot.belongs(to: account) else { return [] }
            var events = snapshot.windows.compactMap { window -> Self? in
                guard let date = window.resetsAt, date > now else { return nil }
                return Self(id: "\(account.id)/\(window.id)", account: account, date: date, expiration: false, title: window.name, plan: snapshot.planType, windowID: window.id)
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

struct HistoricalEventMarker: Identifiable {
    let events: [HorizonEvent]
    let x: Double
    let lane: Int
    var id: String { events.map(\.id).sorted().joined(separator: "|") }
    var expiration: Bool { events[0].expiration }

    static func layout(events: [HorizonEvent], viewport: HorizonViewport, now: Date) -> [Self] {
        struct Key: Hashable { let date: Date; let expiration: Bool }
        let visible = events.filter {
            let x = viewport.position(at: $0.date) - viewport.scrollOffset
            return $0.date <= now && x >= 10 && x <= viewport.viewportWidth - 10
        }
        let groups = Dictionary(grouping: visible) { Key(date: $0.date, expiration: $0.expiration) }
        let keys = groups.keys.sorted { $0.date == $1.date ? !$0.expiration && $1.expiration : $0.date < $1.date }
        var laneEnds: [Double] = []
        return keys.map { key in
            let x = viewport.position(at: key.date)
            let lane = laneEnds.firstIndex { x - 11 >= $0 + 2 } ?? laneEnds.count
            if lane == laneEnds.count { laneEnds.append(0) }
            laneEnds[lane] = x + 11
            return Self(events: groups[key]!.sorted { $0.id < $1.id }, x: x, lane: lane)
        }
    }
}

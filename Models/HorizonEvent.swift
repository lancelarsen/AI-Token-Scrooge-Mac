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
        let accountOrder = Dictionary(uniqueKeysWithValues: AccountPolicy.ordered(state).enumerated().map { ($0.element.id, $0.offset) })
        return state.accounts.filter { $0.enabled && !state.settings.hiddenHistoryAccounts.contains($0.id) }.flatMap { account -> [Self] in
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
        }.sorted { left, right in
            if left.date != right.date { return left.date < right.date }
            // Windows concatenates ordered quota rows before earned resets, then
            // stably sorts by timestamp. Preserve that order for tied events.
            if left.expiration != right.expiration { return !left.expiration }
            if !left.expiration {
                return accountOrder[left.account.id, default: Int.max] < accountOrder[right.account.id, default: Int.max]
            }
            return false
        }
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
        }.sorted { $0.date < $1.date }
        // Windows stably sorts visible series by time, then groups in first-seen
        // order. Preserve account order in popup details and tied marker lanes.
        let groups = Dictionary(grouping: visible) { Key(date: $0.date, expiration: $0.expiration) }
        var seen: Set<Key> = []
        let keys = visible.compactMap { event -> Key? in
            let key = Key(date: event.date, expiration: event.expiration)
            return seen.insert(key).inserted ? key : nil
        }
        var laneEnds: [Double] = []
        return keys.map { key in
            let x = viewport.position(at: key.date)
            let lane = laneEnds.firstIndex { x - 11 >= $0 + 2 } ?? laneEnds.count
            if lane == laneEnds.count { laneEnds.append(0) }
            laneEnds[lane] = x + 11
            return Self(events: groups[key]!, x: x, lane: lane)
        }
    }
}

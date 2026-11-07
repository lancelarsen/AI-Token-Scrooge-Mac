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

    static func layout(events: [HorizonEvent], viewport: HorizonViewport, now: Date,
                       project: ((Date) -> Double)? = nil) -> [Self] {
        // Panning changes the visible interval, not an event's content position.
        // The dashboard already prepares these calendar projections with history.
        let position = project ?? { viewport.position(at: $0) }
        struct Key: Hashable { let date: Date; let expiration: Bool }
        let visible = events.filter {
            let x = position($0.date) - viewport.scrollOffset
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
            let x = position(key.date)
            let lane = laneEnds.firstIndex { x - 11 >= $0 + 2 } ?? laneEnds.count
            if lane == laneEnds.count { laneEnds.append(0) }
            laneEnds[lane] = x + 11
            return Self(events: groups[key]!, x: x, lane: lane)
        }
    }
}

// Reporting coverage is derived from the saved snapshot, including older
// snapshots. Missing fields never create quota windows or synthetic events.
extension QuotaSnapshot {
    func missingWindowNames(for provider: Provider) -> [String] {
        guard provider == .codex || provider == .claude else { return [] }
        let periods = Set(windows.compactMap(\.durationMinutes))
        var missing: [String] = []
        if !periods.contains(300) { missing.append("5-hour limit") }
        if !periods.contains(10080) { missing.append("weekly limit") }
        return missing
    }

    func reportingNote(for provider: Provider) -> String? {
        var missing = missingWindowNames(for: provider)
        if provider == .codex {
            if reserve?.availableCount == nil { missing.append("earned reset count") }
            else if expirationDatesIncomplete { missing.append("some reset expiration times") }
        }
        return missing.isEmpty ? nil : "Not reported: " + missing.joined(separator: ", ")
    }

    var expirationDatesIncomplete: Bool {
        guard let reserve, let count = reserve.availableCount else { return true }
        if count == 0 { return false }
        let dated = reserve.credits?.filter { $0.status == "available" && $0.expiresAt != nil }.count ?? 0
        return dated < count
    }
}

extension HorizonEvent {
    static func refreshCoverageIncomplete(account: ProviderAccount, snapshot: QuotaSnapshot?) -> Bool {
        guard let snapshot, snapshot.belongs(to: account) else { return true }
        return snapshot.windows.isEmpty
            || !snapshot.missingWindowNames(for: account.provider).isEmpty
            || snapshot.windows.contains { $0.resetsAt == nil }
    }

    static func legendCount(_ count: Int, incomplete: Bool) -> String {
        if !incomplete { return String(count) }
        return count == 0 ? "Not reported" : "\(count) reported"
    }
}

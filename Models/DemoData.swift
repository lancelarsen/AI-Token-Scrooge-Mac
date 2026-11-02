import Foundation

enum DemoData {
    static func make(now: Date) -> (PersistedState, [HistoryRun]) {
        var state = PersistedState()
        state.settings.accountSort = .custom
        var runs: [HistoryRun] = []
        let configs: [(Provider, String, String, String, [Decimal])] = [
            (.codex,"Personal","Plus","#D58FAF",[38,74]), (.copilot,"Work","Max","#C9DF75",[86]),
            (.codex,"Work","Pro","#B5A0F4",[61,24]), (.claude,"Personal","Pro","#58A6FF",[93,56])
        ]
        for (index, config) in configs.enumerated() {
            let account = ProviderAccount(id: "demo-\(index)", provider: config.0, nickname: config.1, subject: "demo-\(index)", scope: "demo", lineColor: config.3)
            state.accounts.append(account)
            let windows = config.4.enumerated().map { offset, usage in
                QuotaWindow(id: config.0 == .copilot ? "copilot/monthly" : "window-\(offset)", name: config.0 == .copilot ? "AI Credits · Monthly" : offset == 0 ? "\(config.0 == .codex ? "Codex" : "Current Session") · 5-Hour" : "\(config.0 == .codex ? "Codex" : "Claude") · Weekly",
                            unit: .percent, used: usage, limit: 100, resetsAt: now.addingTimeInterval(Double(offset == 0 ? 8000 + index * 5400 : 170000 + index * 32000)),
                            durationMinutes: offset == 0 ? 300 : 10080, allowanceSource: .provider)
            }
            let reserve: ResetReserve? = config.0 == .codex ? ResetReserve(availableCount: 1, credits: [.init(id: "credit-\(index)", status: "available", expiresAt: now.addingTimeInterval(Double(3 + index * 2) * 86400))]) : nil
            let snapshot = QuotaSnapshot(accountID: account.id, subject: account.subject, scope: account.scope, observedAt: now, windows: windows, reserve: reserve, health: .demo, planType: config.2)
            state.snapshots[account.id] = snapshot
            runs += history(account: account, current: snapshot, index: index, now: now, zone: state.settings.zone)
        }
        state.settings.accountOrder = state.accounts.map(\.id)
        return (state, runs)
    }
    // Mirrors HistoryDemo.cs: synthetic sessions, exact current endpoint, explicit gaps.
    private static func history(account: ProviderAccount, current: QuotaSnapshot, index: Int, now: Date, zone: TimeZone) -> [HistoryRun] {
        guard let window = UsageHistory.selectWindow(provider: account.provider, windows: current.windows).window,
              let endRemaining = window.remainingPercent else { return [] }
        let start = HorizonViewport(now: now, furthestFuture: nil, zone: zone, width: 700).date(at: 0)
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = zone
        var refresh = window.resetsAt.flatMap { calendar.date(byAdding: account.provider == .copilot ? .month : .day, value: account.provider == .copilot ? -1 : -7, to: $0) }
        if let date = refresh, date <= start || date >= now { refresh = nil }
        let expiry = account.provider == .codex && index == 0 ? start.addingTimeInterval(4.25 * 86400) : nil
        let startRemaining = min(99, max(Decimal(78 - index * 4), endRemaining + 35))
        let restored = min(99, max(endRemaining, index % 2 == 0 ? 91 : 96))
        let steps = Int(ceil(now.timeIntervalSince(start) / 300))
        var activity = Array(repeating: 0.0, count: steps + 1)
        for i in 1...steps {
            let date = start.addingTimeInterval(Double(i) * 300)
            let hour = calendar.component(.hour, from: date)
            let slot = hour * 12 + calendar.component(.minute, from: date) / 5
            let day = calendar.ordinality(of: .day, in: .year, for: date)!
            var seed = UInt32(truncatingIfNeeded: day * 7919 + slot * 104729 + index * 15485863)
            seed ^= seed >> 16; seed = seed &* 0x7feb352d; seed ^= seed >> 15
            let session = (slot + index * 17 + day * 7) % 91
            let active = hour >= 8 + index % 3 && hour < 23 - index % 2 && session < 33
            let weight = active && seed % 7 < 3 ? 1 + Double(seed / 7 % 9) / 3 : 0
            activity[i] = activity[i - 1] + weight
        }
        func activityAt(_ date: Date) -> Double { activity[min(steps, max(0, Int(ceil(date.timeIntervalSince(start) / 300))))] }
        func interpolate(_ first: Decimal, _ last: Decimal, at: Date, from: Date, to: Date) -> Decimal {
            let difference = activityAt(to) - activityAt(from)
            let fraction = difference > 0 ? (activityAt(at) - activityAt(from)) / difference : (to <= from ? 1 : at.timeIntervalSince(from) / to.timeIntervalSince(from))
            return first + (last - first) * Decimal(min(1, max(0, fraction)))
        }
        return (0...steps).compactMap { step in
            let at = step == steps ? now : start.addingTimeInterval(Double(step) * 300)
            if account.provider == .claude && at > start.addingTimeInterval(99 * 3600) && at < start.addingTimeInterval(102 * 3600) { return nil }
            var remaining: Decimal
            if let refresh {
                remaining = at < refresh
                    ? interpolate(startRemaining, Decimal(24 + index * 3), at: at, from: start, to: refresh)
                    : interpolate(restored, endRemaining, at: at, from: refresh, to: now)
            } else { remaining = interpolate(startRemaining, endRemaining, at: at, from: start, to: now) }
            var rounded = Decimal()
            NSDecimalRound(&rounded, &remaining, account.provider == .copilot ? 1 : 0, .bankers)
            remaining = at == now ? endRemaining : rounded
            var period = window
            period.used = (window.unit == .percent ? 100 : window.limit ?? 100) * (100 - remaining) / 100
            if let refresh, at < refresh { period.resetsAt = refresh }
            var snapshot = current
            snapshot.observedAt = at; snapshot.providerDataAt = at; snapshot.windows = [period]
            snapshot.reserve = expiry.flatMap { date in at <= date ? ResetReserve(availableCount: 1, credits: [.init(id: "demo-history-expiry:\(account.id)", status: "available", expiresAt: date)]) : nil }
            return HistoryRun(snapshot: snapshot, lastObservedAt: at, pollingMinutes: 5)
        }
    }

}

import Foundation

enum DemoData {
    enum Scenario: String, CaseIterable {
        case standard, offline, auth, permission, unknown, exhausted, due, partial
        case historyLong = "history-long"
        case reserveOnly = "reserve-only"
        case healthy, noReset = "no-reset"
        case alertHistory = "alert-history"
    }

    static func make(now: Date, scenario: Scenario = .standard) -> (PersistedState, [HistoryRun]) {
        var state = PersistedState()
        state.settings.accountSort = .custom
        var runs: [HistoryRun] = []
        let configs: [(Provider, String, String, String, [Decimal])] = [
            (.codex,"Personal","plus","#D587A5",[38,74]), (.copilot,"Work","individual_max","#CDEB82",[8200]),
            (.codex,"Work","pro","#B99AF8",[19,58]), (.claude,"Personal","pro","#58A6FF",[12,94])
        ]
        for (index, config) in configs.enumerated() {
            let identities = [("demo@example.invalid", "demo"), ("demo-github", "personal"),
                              ("work@example.invalid", "demo-work"), ("claude@example.invalid", "demo-claude")]
            let identity = identities[index]
            let account = ProviderAccount(id: "demo-\(index)", provider: config.0, nickname: config.1, subject: identity.0, scope: identity.1, lineColor: config.3)
            state.accounts.append(account)
            var utc = Calendar(identifier: .gregorian); utc.timeZone = TimeZone(secondsFromGMT: 0)!
            let nextMonth = utc.date(byAdding: .month, value: 1, to: utc.date(from: utc.dateComponents([.year, .month], from: now))!)!
            let windows = config.4.enumerated().map { offset, usage in
                let copilot = config.0 == .copilot
                let session = offset == 0
                let reset: Date = copilot ? nextMonth : now.addingTimeInterval(
                    session ? (index == 0 ? 8040 : index == 2 ? 13440 : 10800) : Double(index == 0 ? 2 : index == 2 ? 5 : 4) * 86400)
                return QuotaWindow(id: copilot ? "copilot/monthly" : config.0 == .codex ? (session ? "codex/primary" : "codex/secondary") : (session ? "session" : "weekly"),
                    name: copilot ? "AI Credits · Monthly (10,000)" : config.0 == .codex ? (session ? "Codex · 5-Hour" : "Codex · Weekly") : (session ? "Current Session" : "Weekly Limit"),
                    unit: copilot ? .credits : .percent, used: usage, limit: copilot ? 10000 : 100,
                    resetsAt: reset, durationMinutes: copilot ? nil : session ? 300 : 10080, allowanceSource: .provider)
            }
            let reserve: ResetReserve? = index == 0 ? ResetReserve(availableCount: 2, credits: [
                .init(id: "demo-r1", status: "available", expiresAt: now.addingTimeInterval(4 * 86400)),
                .init(id: "demo-r2", status: "available", expiresAt: now.addingTimeInterval(9 * 86400))]) : nil
            var snapshot = QuotaSnapshot(accountID: account.id, subject: account.subject, scope: account.scope, observedAt: now, windows: windows, reserve: reserve, health: .demo, planType: config.2)
            switch scenario {
            case .standard, .alertHistory: break
            case .healthy: snapshot.health = .healthy
            case .offline:
                snapshot.health = .offline
                snapshot.message = "Demo: network unavailable; last successful values retained."
            case .auth:
                snapshot.health = .authenticationRequired
                snapshot.message = "Demo: reconnect this account to resume monitoring."
            case .permission:
                snapshot.health = .permissionRequired
                snapshot.message = "Demo: billing read access is unavailable."
            case .reserveOnly:
                snapshot.windows = []
                snapshot.message = "Demo: source reported reset credits without quota windows."
            case .historyLong:
                if var reserve = snapshot.reserve {
                    reserve.availableCount = 3
                    reserve.credits = (reserve.credits ?? []) + [.init(id: "demo-long-horizon", status: "available", expiresAt: now.addingTimeInterval(35 * 86400))]
                    snapshot.reserve = reserve
                }
            case .partial:
                if snapshot.reserve != nil {
                    snapshot.reserve = ResetReserve(availableCount: 3, credits: [.init(id: "sample-credit", status: "available", expiresAt: now.addingTimeInterval(45 * 60))])
                }
            case .unknown, .exhausted, .due, .noReset:
                snapshot.windows = snapshot.windows.map { original in
                    var window = original
                    switch scenario {
                    case .unknown: window.used = nil; window.limit = nil
                    case .exhausted: window.used = window.unit == .percent ? 100 : window.limit
                    case .due: window.resetsAt = now.addingTimeInterval(-60)
                    case .noReset: window.resetsAt = nil
                    default: break
                    }
                    return window
                }
            }
            state.snapshots[account.id] = snapshot
            runs += history(account: account, current: snapshot, index: index, now: now, zone: state.settings.zone)
        }
        state.settings.accountOrder = state.accounts.map(\.id)
        if scenario == .alertHistory, let account = state.accounts.first {
            state.alerts = (0..<8).map { index in
                let refresh = index % 4 == 3
                let expiration = index % 4 == 2
                let reminder = refresh || expiration
                return AlertEvent(id: "demo-alert-\(index)", accountID: account.id,
                    windowID: expiration ? nil : "codex/secondary",
                    title: reminder ? "\(refresh ? "Critical" : "Warning") Alert · \(refresh ? "Quota Refresh" : "Reset Expiration")" : "Codex · Weekly Is Running Low",
                    detail: reminder ? "\(expiration ? "Earned Reset" : "Codex · Weekly") · In 2d 17h · \(account.nickname)" : "27% Left · OpenAI / \(account.nickname)",
                    createdAt: now.addingTimeInterval(-Double(index) * 3600), delivered: index != 0,
                    severity: refresh ? .critical : .warning,
                    reminderID: reminder ? "demo-reminder-\(index)" : nil, isRefreshReminder: refresh)
            }
        }
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

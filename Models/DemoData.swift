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
            for sample in 0..<5040 {
                var historic = snapshot
                historic.observedAt = now.addingTimeInterval(Double(sample - 5040) * 120)
                for w in historic.windows.indices {
                    let cycle = w == 0 ? 51 : 121
                    let phase = (sample / 30 + index * 11) % cycle
                    historic.windows[w].used = Decimal(min(98, (phase / 3) * 5 + index * 4))
                }
                runs.append(HistoryRun(snapshot: historic, lastObservedAt: historic.observedAt, pollingMinutes: 2))
            }
        }
        state.settings.accountOrder = state.accounts.map(\.id)
        return (state, runs)
    }
}

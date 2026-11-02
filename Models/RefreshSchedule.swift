import Foundation

struct RefreshSchedule: Sendable {
    private var due: [String: Date] = [:]
    private var throttled: [String: Date] = [:]
    private var failures: [String: Int] = [:]
    mutating func reset() { due.removeAll(); throttled.removeAll(); failures.removeAll() }
    func shouldRefresh(_ id: String, now: Date, force: Bool) -> Bool {
        if let until = throttled[id], until > now { return false }
        return force || (due[id] ?? .distantPast) <= now
    }
    mutating func succeeded(_ snapshot: QuotaSnapshot, account: ProviderAccount, now: Date) {
        failures[account.id] = 0; throttled.removeValue(forKey: account.id)
        due[account.id] = AccountPolicy.nextRefresh(snapshot: snapshot, account: account, now: now)
    }
    mutating func failed(_ id: String, now: Date, retryAt: Date?) {
        let count = min(5, (failures[id] ?? 0) + 1); failures[id] = count
        due[id] = retryAt ?? now.addingTimeInterval(min(1800, 60 * pow(2, Double(count))))
        if let retryAt { throttled[id] = retryAt }
    }
}

enum AlertDeliveryPolicy {
    static func canDeliver(_ alert: AlertEvent, state: PersistedState, now: Date) -> Bool {
        guard !alert.dismissed, state.settings.notifications, !state.settings.isQuiet(at: now),
              state.accounts.contains(where: { $0.id == alert.accountID && $0.enabled }),
              AlertEvaluator.isEnabled(alert, settings: state.settings, snapshot: state.snapshots[alert.accountID]) else { return false }
        return !state.alerts.contains { $0.accountID == alert.accountID && ($0.snoozedUntil ?? .distantPast) > now }
    }
}

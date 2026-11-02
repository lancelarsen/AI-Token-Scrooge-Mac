import Foundation

struct AlertEvent: Codable, Identifiable, Equatable, Sendable {
    var id: String
    var accountID: String
    var windowID: String?
    var title: String
    var detail: String
    var createdAt: Date
    var delivered = false
    var severity: ReminderSeverity?
    var reminderID: String?
    var isRefreshReminder = false
    var snoozedUntil: Date?
    var dismissed = false
}

enum AlertEvaluator {
    static func isEnabled(_ alert: AlertEvent, settings: RadarSettings, snapshot: QuotaSnapshot? = nil) -> Bool {
        if let window = alert.windowID, !settings.capacityAlertsEnabled(accountID: alert.accountID, windowID: window) { return false }
        if alert.reminderID != nil, !alert.isRefreshReminder, let snapshot, !snapshot.windows.isEmpty,
           !snapshot.windows.contains(where: { settings.capacityAlertsEnabled(accountID: alert.accountID, windowID: $0.id) }) { return false }
        if let reminder = alert.reminderID {
            return (alert.isRefreshReminder || settings.rule(accountID: alert.accountID).expiry)
                && (alert.isRefreshReminder ? settings.quotaRefreshReminders : settings.resetExpiryReminders).contains { $0.id == reminder && $0.isValid }
        }
        return true
    }
    static func evaluate(account: ProviderAccount, previous: QuotaSnapshot?, current: QuotaSnapshot, settings: RadarSettings, now: Date) -> [AlertEvent] {
        guard current.health == .healthy else { return [] }
        var alerts: [AlertEvent] = []
        for window in current.windows {
            guard settings.capacityAlertsEnabled(accountID: account.id, windowID: window.id) else { continue }
            let before = previous?.windows.first { $0.id == window.id }
            if let reset = window.resetsAt, let reminder = TimedReminder.due(settings.quotaRefreshReminders, at: reset, now: now) {
                let movingEstimate = before?.resetsAt.map { prior in
                    prior != reset && prior > now && abs(reset.timeIntervalSince(prior)) <= 600
                    && previous.map { TimedReminder.due(settings.quotaRefreshReminders, at: prior, now: $0.observedAt)?.id == reminder.id } == true
                } ?? false
                if !movingEstimate { alerts.append(makeReminder(account: account, windowID: window.id, target: window.id, at: reset, reminder: reminder, refresh: true, now: now, name: window.name, settings: settings)) }
            }
            let rule = settings.rule(accountID: account.id, windowID: window.id)
            let thresholds = rule.thresholds ?? settings.thresholds
            let state = window.capacity(thresholds)
            let period = window.resetsAt.map { String(Int64($0.timeIntervalSince1970)) } ?? "unknown"
            let threshold: Decimal = switch state { case .exhausted: 0; case .critical: thresholds.critical; case .info: thresholds.info; default: thresholds.warning }
            let crossed = before?.remainingPercent == nil || before?.resetsAt != window.resetsAt || (before?.remainingPercent ?? 0) > threshold
            let enabled = switch state { case .info: rule.info; case .low: rule.low; case .critical: rule.critical; case .exhausted: rule.exhausted; default: false }
            if crossed && enabled {
                let title = state == .exhausted ? "\(window.name) Is Exhausted" : state == .info ? "\(window.name) Info Alert" : "\(window.name) Is Running Low"
                alerts.append(AlertEvent(id: "\(account.id)/\(window.id)/\(period)/\(state.rawValue)", accountID: account.id, windowID: window.id,
                                         title: title, detail: "\(Format.percent(window.remainingPercent)) Left · \(account.provider.rawValue) / \(account.nickname)", createdAt: now,
                                         severity: state == .info ? .info : state == .low ? .warning : .critical))
            }
            if rule.restored, before?.capacity() == .exhausted, let left = window.remainingPercent, left > 0, current.usageAllowed == true {
                alerts.append(AlertEvent(id: "\(account.id)/\(window.id)/\(period)/restored", accountID: account.id, windowID: window.id,
                                         title: "\(window.name) Is Available Again", detail: "Provider confirmed capacity · \(account.provider.rawValue) / \(account.nickname)", createdAt: now))
            }
        }
        if settings.rule(accountID: account.id).expiry, current.reserve?.availableCount != 0 {
            for credit in current.reserve?.credits ?? [] where credit.status == "available" {
                if let expiry = credit.expiresAt, let reminder = TimedReminder.due(settings.resetExpiryReminders, at: expiry, now: now) {
                    alerts.append(makeReminder(account: account, windowID: nil, target: credit.id, at: expiry, reminder: reminder, refresh: false, now: now, name: "Earned Reset", settings: settings))
                }
            }
        }
        return alerts.filter { isEnabled($0, settings: settings, snapshot: current) }
    }
    private static func makeReminder(account: ProviderAccount, windowID: String?, target: String, at: Date, reminder: TimedReminder, refresh: Bool, now: Date, name: String, settings: RadarSettings) -> AlertEvent {
        AlertEvent(id: "\(account.id)/\(refresh ? "refresh" : "credit")/\(target)/\(Int64(at.timeIntervalSince1970))/\(reminder.id)", accountID: account.id,
                   windowID: windowID, title: "\(reminder.severity.rawValue) Alert · \(refresh ? "Quota Refresh" : "Reset Expiration")",
                   detail: "\(name) · \(Format.countdown(at, now: now)) · \(Format.date(at, zone: settings.zone)) · \(account.nickname)", createdAt: now,
                   severity: reminder.severity, reminderID: reminder.id, isRefreshReminder: refresh)
    }
}


/// Current quota status is independent of popup delivery, quiet hours and snooze.
enum IconAlertPolicy {
    static func evaluate(state: PersistedState, now: Date) -> AlertEvent? {
        guard state.settings.alertOnIcon else { return nil }
        func rank(_ severity: ReminderSeverity?) -> Int {
            switch severity { case .critical: 3; case .warning: 2; case .info: 1; case nil: 0 }
        }
        var highest: AlertEvent?
        for account in state.accounts where account.enabled {
            guard let snapshot = state.snapshots[account.id], snapshot.belongs(to: account) else { continue }
            for alert in AlertEvaluator.evaluate(account: account, previous: nil, current: snapshot, settings: state.settings, now: now) {
                if rank(alert.severity) > rank(highest?.severity) { highest = alert }
            }
        }
        return highest
    }
}

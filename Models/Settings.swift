import Foundation

struct AlertThresholds: Codable, Equatable, Sendable {
    var warning: Decimal = 30
    var critical: Decimal = 10
    var info: Decimal = 50
    var isValid: Bool { critical >= 0 && critical < warning && warning <= info && info <= 100 }
    static func remaining(at position: Double, width: Double) -> Decimal {
        guard width > 0, width.isFinite, position.isFinite else { return 0 }
        return Decimal((min(1, max(0, 1 - position / width)) * 100).rounded(.toNearestOrAwayFromZero))
    }
    mutating func move(_ level: ReminderSeverity, to remaining: Decimal) {
        var number = remaining
        var rounded = Decimal()
        NSDecimalRound(&rounded, &number, 0, level == .info ? .bankers : .plain)
        var warningCeiling = Decimal()
        var criticalFloor = Decimal()
        var warningValue = warning
        var criticalValue = critical
        NSDecimalRound(&warningCeiling, &warningValue, 0, .up)
        NSDecimalRound(&criticalFloor, &criticalValue, 0, .down)
        switch level {
        case .info: info = min(100, max(warning, rounded))
        case .warning: warning = min(info, max(criticalFloor + 1, rounded))
        case .critical: critical = min(warningCeiling - 1, max(0, rounded))
        }
    }
}
enum ReminderSeverity: String, Codable, CaseIterable, Sendable { case info = "Info", warning = "Warning", critical = "Critical" }
extension AlertThresholds {
    init(from decoder: Decoder) throws {
        self.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        warning = try values.decodeIfPresent(Decimal.self, forKey: .warning) ?? warning
        critical = try values.decodeIfPresent(Decimal.self, forKey: .critical) ?? critical
        info = try values.decodeIfPresent(Decimal.self, forKey: .info) ?? info
    }
}
struct TimedReminder: Codable, Identifiable, Equatable, Sendable {
    var id: String = UUID().uuidString
    var amount: Int
    var unit: String
    var severity: ReminderSeverity
    var hours: Double { Double(amount) * (unit == "Days" ? 24 : 1) }
    var isValid: Bool { amount > 0 && ["Days", "Hours"].contains(unit) }
    static func defaults(expiration: Bool) -> [Self] {
        (expiration ? [240,120,72,48,24,12,6,3,1] : [120,72,48,24,12,6,3,1]).map { h in
            Self(id: "default-\(h)", amount: h >= 24 ? h / 24 : h, unit: h >= 24 ? "Days" : "Hours",
                 severity: h >= 120 ? .info : h >= 72 ? .warning : .critical)
        }
    }
    static func due(_ reminders: [Self], at: Date, now: Date) -> Self? {
        guard at > now else { return nil }
        return reminders.filter { $0.isValid && at.timeIntervalSince(now) / 3600 <= $0.hours }
            .sorted { $0.hours == $1.hours ? $0.severity.rank > $1.severity.rank : $0.hours < $1.hours }.first
    }
}
extension ReminderSeverity { var rank: Int { switch self { case .info: 0; case .warning: 1; case .critical: 2 } } }
enum AccountSort: String, Codable, CaseIterable, Sendable {
    case custom = "Custom Order", mostRemaining = "Most Remaining", leastRemaining = "Least Remaining", nextReset = "Next Reset"
}
struct AlertRule: Codable, Equatable, Sendable {
    var accountID: String
    var windowID: String?
    var thresholds: AlertThresholds?
    var info = true
    var low = true
    var critical = true
    var exhausted = true
    var restored = true
    var expiry = true
}
struct QuotaAlertSection: Codable, Equatable, Sendable { var accountID: String; var windowID: String }
extension AlertRule {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(accountID: try values.decode(String.self, forKey: .accountID))
        windowID = try values.decodeIfPresent(String.self, forKey: .windowID)
        thresholds = try values.decodeIfPresent(AlertThresholds.self, forKey: .thresholds)
        info = try values.decodeIfPresent(Bool.self, forKey: .info) ?? info
        low = try values.decodeIfPresent(Bool.self, forKey: .low) ?? low
        critical = try values.decodeIfPresent(Bool.self, forKey: .critical) ?? critical
        exhausted = try values.decodeIfPresent(Bool.self, forKey: .exhausted) ?? exhausted
        restored = try values.decodeIfPresent(Bool.self, forKey: .restored) ?? restored
        expiry = try values.decodeIfPresent(Bool.self, forKey: .expiry) ?? expiry
    }
}

/// Keep incomplete quiet-hours edits visible without replacing the last saved
/// interval. Equal endpoints are permitted only while delivery quieting is off.
struct QuietHoursDraft: Equatable, Sendable {
    var enabled: Bool
    var start: Int
    var end: Int

    init(settings: RadarSettings) {
        enabled = settings.quietHours
        start = settings.quietStartHour
        end = settings.quietEndHour
    }
    var isValid: Bool {
        (0...23).contains(start) && (0...23).contains(end) && (!enabled || start != end)
    }
    @discardableResult
    func apply(to settings: inout RadarSettings) -> Bool {
        guard isValid else { return false }
        settings.quietHours = enabled
        settings.quietStartHour = start
        settings.quietEndHour = end
        return true
    }
}

struct RadarSettings: Codable, Equatable, Sendable {
    // Defaults match RadarSettings.cs at Windows fc37458, not a user's saved preferences.
    var notifications = true
    var sound = true
    var privacy = false
    var quietHours = true
    var quietStartHour = 0
    var quietEndHour = 8
    var thresholds = AlertThresholds()
    var launchAtSignIn = true
    var closeToMenuBar = true
    var timeZoneID = "America/Chicago"
    var accountSort: AccountSort = .custom
    var accountOrder: [String] = []
    var disabledCapacityAlerts: [QuotaAlertSection] = []
    var rules: [AlertRule] = []
    var soundTheme = "Ducks"
    var soundVolume = 65.0
    var alertOnIcon = true
    var resetExpiryReminders = TimedReminder.defaults(expiration: true)
    var quotaRefreshReminders = TimedReminder.defaults(expiration: false)
    var historyRetentionDays = 90
    var historyEnabled = true
    var hiddenHistoryAccounts: Set<String> = []
    var customColors: [String] = []
    init() {}
    private enum CodingKeys: String, CodingKey {
        case notifications, sound, privacy, quietHours, quietStartHour, quietEndHour, thresholds, launchAtSignIn, closeToMenuBar, timeZoneID, accountSort, accountOrder, disabledCapacityAlerts, rules, soundTheme, soundVolume, alertOnIcon, resetExpiryReminders, quotaRefreshReminders, historyRetentionDays, historyEnabled, hiddenHistoryAccounts, customColors
    }
    init(from decoder: Decoder) throws {
        self.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        notifications = try values.decodeIfPresent(Bool.self, forKey: .notifications) ?? notifications
        sound = try values.decodeIfPresent(Bool.self, forKey: .sound) ?? sound
        privacy = try values.decodeIfPresent(Bool.self, forKey: .privacy) ?? privacy
        quietHours = try values.decodeIfPresent(Bool.self, forKey: .quietHours) ?? quietHours
        quietStartHour = try values.decodeIfPresent(Int.self, forKey: .quietStartHour) ?? quietStartHour
        quietEndHour = try values.decodeIfPresent(Int.self, forKey: .quietEndHour) ?? quietEndHour
        thresholds = try values.decodeIfPresent(AlertThresholds.self, forKey: .thresholds) ?? thresholds
        launchAtSignIn = try values.decodeIfPresent(Bool.self, forKey: .launchAtSignIn) ?? launchAtSignIn
        closeToMenuBar = try values.decodeIfPresent(Bool.self, forKey: .closeToMenuBar) ?? closeToMenuBar
        timeZoneID = try values.decodeIfPresent(String.self, forKey: .timeZoneID) ?? timeZoneID
        accountSort = try values.decodeIfPresent(AccountSort.self, forKey: .accountSort) ?? accountSort
        accountOrder = try values.decodeIfPresent([String].self, forKey: .accountOrder) ?? accountOrder
        disabledCapacityAlerts = try values.decodeIfPresent([QuotaAlertSection].self, forKey: .disabledCapacityAlerts) ?? disabledCapacityAlerts
        rules = try values.decodeIfPresent([AlertRule].self, forKey: .rules) ?? rules
        soundTheme = try values.decodeIfPresent(String.self, forKey: .soundTheme) ?? soundTheme
        soundVolume = try values.decodeIfPresent(Double.self, forKey: .soundVolume) ?? soundVolume
        alertOnIcon = try values.decodeIfPresent(Bool.self, forKey: .alertOnIcon) ?? alertOnIcon
        resetExpiryReminders = try values.decodeIfPresent([TimedReminder].self, forKey: .resetExpiryReminders) ?? resetExpiryReminders
        quotaRefreshReminders = try values.decodeIfPresent([TimedReminder].self, forKey: .quotaRefreshReminders) ?? quotaRefreshReminders
        historyRetentionDays = try values.decodeIfPresent(Int.self, forKey: .historyRetentionDays) ?? historyRetentionDays
        historyEnabled = try values.decodeIfPresent(Bool.self, forKey: .historyEnabled) ?? historyEnabled
        hiddenHistoryAccounts = try values.decodeIfPresent(Set<String>.self, forKey: .hiddenHistoryAccounts) ?? hiddenHistoryAccounts
        customColors = try values.decodeIfPresent([String].self, forKey: .customColors) ?? customColors
        do {
            try validate()
        } catch {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: error.localizedDescription))
        }
    }
    func validate() throws {
        guard thresholds.isValid, rules.allSatisfy({ $0.thresholds?.isValid ?? true }) else { throw PreferenceError.invalidThresholds }
        guard (0...23).contains(quietStartHour), (0...23).contains(quietEndHour),
              soundVolume.isFinite, (0...100).contains(soundVolume), (1...365).contains(historyRetentionDays) else {
            throw PreferenceError.invalidRange
        }
    }
    var zone: TimeZone { TimeZone(identifier: timeZoneID) ?? TimeZone(identifier: "America/Chicago")! }
    func capacityAlertsEnabled(accountID: String, windowID: String) -> Bool {
        !disabledCapacityAlerts.contains(.init(accountID: accountID, windowID: windowID))
    }
    func rule(accountID: String, windowID: String? = nil) -> AlertRule {
        let account = rules.first { $0.accountID == accountID && $0.windowID == nil } ?? AlertRule(accountID: accountID)
        var result = windowID.flatMap { window in rules.first { $0.accountID == accountID && $0.windowID == window } } ?? account
        result.thresholds = result.thresholds ?? account.thresholds ?? thresholds
        return result
    }
    func isQuiet(at now: Date) -> Bool {
        guard quietHours else { return false }
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = zone
        let hour = calendar.component(.hour, from: now)
        return quietStartHour <= quietEndHour
            ? hour >= quietStartHour && hour < quietEndHour
            : hour >= quietStartHour || hour < quietEndHour
    }
}

enum PreferenceError: LocalizedError {
    case invalidThresholds, invalidRange

    var errorDescription: String? {
        switch self {
        case .invalidThresholds: "Alert levels must satisfy Critical < Warning ≤ Info, between 0 and 100."
        case .invalidRange: "The selected preference is outside its supported range."
        }
    }
}

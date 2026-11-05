import Foundation

enum Format {
    /// Windows ActionButton.GlyphFor mapping, also used by themed dialog actions.
    static func actionGlyph(_ title: String) -> String {
        let value = title.lowercased()
        if value == "check now" || value == "update and restart" { return "\u{E72C}" }
        if value == "get update" { return "\u{E896}" }
        if value.hasPrefix("preview") { return "\u{E768}" }
        if value == "show info" { return "\u{E946}" }
        if value == "custom order" { return "\u{E80A}" }
        if value == "most remaining" { return "\u{E9D9}" }
        if value == "least remaining" { return "\u{E9D2}" }
        if value == "next reset" { return "\u{E823}" }
        if value.contains("rename") { return "\u{E70F}" }
        if value.hasPrefix("save") { return "\u{E74E}" }
        if value.contains("remove") { return "\u{E74D}" }
        if value.contains("copy") { return "\u{E8C8}" }
        if value.contains("close") || value.contains("cancel") || value.contains("dismiss") { return "\u{E711}" }
        if value.contains("snooze") { return "\u{E823}" }
        if value.contains("refresh") || value.contains("default") { return "\u{E72C}" }
        if value.contains("settings") || value.contains("manage account") || value.contains("rules") { return "\u{E713}" }
        if value.contains("history") { return "\u{E81C}" }
        if value.contains("notification") { return "\u{E7F4}" }
        if value.contains("help") { return "\u{E897}" }
        if value.contains("quick view") || value.contains("dashboard") { return "\u{E80F}" }
        if value.contains("token") { return "\u{E8D7}" }
        if value.contains("sign in") || value.contains("connect") || ["openai codex", "github copilot", "claude"].contains(value) { return "\u{E77B}" }
        if value.contains("add") { return "\u{E710}" }
        if value.contains("reset") { return "\u{E8B7}" }
        if value.contains("usage") { return "\u{E9D9}" }
        return "\u{E8A7}"
    }

    /// Match ThemedDialogs.ShowAsync: label prefixes are short, non-time text.
    static func dialogLine(_ line: String) -> (label: String?, value: String) {
        guard let colon = line.firstIndex(of: ":") else { return (nil, line) }
        let prefix = line[..<colon]
        guard (1..<45).contains(prefix.utf16.count),
              prefix.unicodeScalars.last?.properties.generalCategory != .decimalNumber else { return (nil, line) }
        return (String(prefix), String(line[line.index(after: colon)...]).replacingOccurrences(of: "^\\s+", with: "", options: .regularExpression))
    }

    private static let titleWordStart = try! NSRegularExpression(pattern: "\\b[a-z]")

    static func windowTitle(_ value: String) -> String {
        let result = NSMutableString(string: value)
        for match in titleWordStart.matches(in: value, range: NSRange(value.startIndex..., in: value)).reversed() {
            result.replaceCharacters(in: match.range, with: result.substring(with: match.range).uppercased())
        }
        return result as String
    }

    static func timeZoneName(_ zone: TimeZone, at date: Date = .now) -> String {
        // Windows DisplayName uses the standard offset even during daylight saving.
        let offset = zone.secondsFromGMT(for: date) - Int(zone.daylightSavingTimeOffset(for: date))
        let minutes = abs(offset) / 60
        let prefix = String(format: "(UTC%@%02d:%02d)", offset < 0 ? "-" : "+", minutes / 60, minutes % 60)
        let name = zone.identifier == "America/Chicago" ? "Central Time (US & Canada)"
            : zone.localizedName(for: .standard, locale: Locale(identifier: "en_US"))
                ?? zone.identifier.replacingOccurrences(of: "_", with: " ")
        let region = zone.identifier.replacingOccurrences(of: "_", with: " ")
        let label = zone.identifier == "America/Chicago" ? name : "\(name) · \(region)"
        return "\(prefix) \(label)"
    }

    static func historyDate(_ date: Date, zone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = zone
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }

    static func snapshotDate(_ date: Date, zone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = zone
        formatter.dateFormat = "M/d/yyyy h:mm a"
        return formatter.string(from: date)
    }

    static func updated(_ date: Date, zone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = zone
        let day = calendar.component(.day, from: date)
        let suffix = (11...13).contains(day) ? "th" : day % 10 == 1 ? "st" : day % 10 == 2 ? "nd" : day % 10 == 3 ? "rd" : "th"
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_US_POSIX"); formatter.timeZone = zone
        formatter.dateFormat = "h:mm a"
        let time = formatter.string(from: date)
        formatter.dateFormat = "EEEE, MMM"
        return "Updated \(time) \(zone.abbreviation(for: date) ?? zone.identifier)\n\(formatter.string(from: date)) \(day)\(suffix)"
    }
    static func plan(_ provider: Provider, _ value: String?) -> String {
        let labels: [String: String]
        switch provider {
        case .codex:
            labels = ["free": "Free", "go": "Go", "plus": "Plus", "pro": "Pro", "prolite": "Pro Lite", "promax": "Pro Max", "team": "Team", "business": "Business", "enterprise": "Enterprise", "edu": "Edu"]
        case .claude:
            labels = ["pro": "Pro", "max": "Max", "team": "Team", "enterprise": "Enterprise"]
        case .copilot:
            labels = ["individual": "Pro", "individual_pro": "Pro+", "individual_max": "Max", "individual_edu": "Education", "business": "Business", "enterprise": "Enterprise"]
        }
        return value.flatMap { labels[$0] } ?? "Plan unavailable"
    }
    static func historyPlanBadge(_ provider: Provider, _ value: String?) -> String {
        let label = plan(provider, value)
        return label == "Plan unavailable" ? (provider == .copilot ? "Monthly" : "Weekly") : label
    }

    static func usageText(_ window: QuotaWindow, provider: Provider, locale: Locale = .current) -> (used: String, left: String) {
        if window.unit == .percent || provider == .copilot {
            return (window.usedPercent.map { "\(percent($0)) used" } ?? "Usage unavailable",
                    window.remainingPercent.map { "\(percent($0)) left" } ?? "Left unavailable")
        }
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.roundingMode = .halfEven
        func count(_ value: Decimal) -> String {
            formatter.string(from: NSDecimalNumber(decimal: value)) ?? NSDecimalNumber(decimal: value).stringValue
        }
        return (window.used.map { "\(count($0)) used" } ?? "Usage unavailable",
                window.remaining.map { $0 < 0 ? "\(count(-$0)) over" : "\(count($0)) left" } ?? "Limit unavailable")
    }

    static func percent(_ value: Decimal?, fractionDigits: Int = 0) -> String {
        guard var number = value else { return "Unknown" }
        var rounded = Decimal(); NSDecimalRound(&rounded, &number, fractionDigits, .plain)
        return "\(NSDecimalNumber(decimal: rounded).stringValue)%"
    }
    static func countdown(_ date: Date?, now: Date = .now) -> String {
        guard let date else { return "Reset Time Unavailable" }
        let seconds = date.timeIntervalSince(now)
        guard seconds > 0 else { return "Reset Due — Checking" }
        let minutes = Int(seconds / 60)
        if minutes < 1 { return "In Less Than a Minute" }
        if minutes >= 1440 { return "\(minutes / 1440)d \((minutes % 1440) / 60)h" }
        if minutes >= 60 { return "\(minutes / 60)h \(minutes % 60)m" }
        return "\(minutes)m"
    }
    static func detailDate(_ date: Date?, zone: TimeZone) -> String {
        guard let date else { return "Not supplied" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = zone
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss xxx"
        return formatter.string(from: date)
    }
    static func date(_ date: Date?, zone: TimeZone) -> String {
        guard let date else { return "Not Supplied by Provider" }
        let formatter = DateFormatter()
        formatter.timeZone = zone; formatter.dateFormat = "EEE, MMM d h:mm a"
        return formatter.string(from: date)
    }
}

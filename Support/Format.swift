import Foundation

enum Format {
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

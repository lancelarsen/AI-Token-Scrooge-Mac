import Foundation

enum ClaudeUsageParser {
    static func parse(_ screen: String, now: Date) -> [QuotaWindow] {
        let definitions = [("Current session", "session", "Current session", 300), ("Current week (all models)", "weekly", "Weekly limit", 10080)]
        return definitions.compactMap { heading, id, name, duration in
            guard let start = screen.range(of: heading) else { return nil }
            var section = String(screen[start.upperBound...])
            if let end = section.range(of: #"\r?\n\s*(?:Current |Extra usage|Esc to cancel)"#, options: .regularExpression) { section = String(section[..<end.lowerBound]) }
            guard let value = captures(#"(?<![\w.+-])(\d+(?:\.\d+)?)% used"#, in: section)?.first,
                  let used = Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")), used >= 0, used <= 100 else { return nil }
            let reset = captures(#"(?i)Resets ([^\r\n(]+)\s*\(([^)]+)\)"#, in: section)
            let date = reset.flatMap { parseReset($0[0].trimmingCharacters(in: .whitespaces), zoneID: $0[1], now: now, duration: duration) }
            return QuotaWindow(id: id, name: name, unit: .percent, used: used, limit: 100, resetsAt: date, durationMinutes: duration, allowanceSource: .provider)
        }
    }
    private static func captures(_ pattern: String, in text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern), let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
        return (1..<match.numberOfRanges).compactMap { Range(match.range(at: $0), in: text).map { String(text[$0]) } }
    }
    static func parseReset(_ text: String, zoneID: String, now: Date, duration: Int) -> Date? {
        guard let zone = TimeZone(identifier: zoneID) else { return nil }
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = zone
        // Parse civil components in UTC first; DateFormatter must not silently repair a DST gap.
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.isLenient = false
        var parsed: Date?
        for format in ["h:mma", "ha", "MMM d, h:mma", "MMM d, ha"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: text) { parsed = date; break }
        }
        guard let parsed else { return nil }
        var utc = Calendar(identifier: .gregorian); utc.timeZone = TimeZone(secondsFromGMT: 0)!
        let clock = utc.dateComponents([.month, .day, .hour, .minute], from: parsed)
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        let hasDate = text.contains(",")
        if hasDate { components.month = clock.month; components.day = clock.day }
        components.hour = clock.hour; components.minute = clock.minute; components.second = 0
        // Find first and last matching civil time; differing results identify an ambiguous fall-back hour.
        func resolve(_ parts: DateComponents) -> Date? {
            var day = parts; day.hour = 0; day.minute = 0; day.second = 0
            guard let midnight = calendar.date(from: day) else { return nil }
            let anchor = midnight.addingTimeInterval(-1)
            guard let first = calendar.nextDate(after: anchor, matching: parts, matchingPolicy: .strict, repeatedTimePolicy: .first),
                  let last = calendar.nextDate(after: anchor, matching: parts, matchingPolicy: .strict, repeatedTimePolicy: .last), first == last,
                  calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: first) == parts else { return nil }
            return first
        }
        guard var date = resolve(components) else { return nil }
        if !hasDate, date < now.addingTimeInterval(-60) {
            guard let next = calendar.date(byAdding: .day, value: 1, to: date) else { return nil }
            let day = calendar.dateComponents([.year, .month, .day], from: next)
            components.year = day.year; components.month = day.month; components.day = day.day
            guard let resolved = resolve(components) else { return nil }; date = resolved
        } else if hasDate, date < now.addingTimeInterval(-86400) {
            components.year = (components.year ?? 0) + 1
            guard let resolved = resolve(components) else { return nil }; date = resolved
        }
        return date >= now.addingTimeInterval(-60) && date <= now.addingTimeInterval(Double(duration + 1) * 60) ? date : nil
    }
}

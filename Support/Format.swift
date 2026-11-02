import Foundation

enum Format {
    static func percent(_ value: Decimal?) -> String {
        guard var number = value else { return "Unknown" }
        var rounded = Decimal(); NSDecimalRound(&rounded, &number, 0, .plain)
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
    static func date(_ date: Date?, zone: TimeZone) -> String {
        guard let date else { return "Not Supplied by Provider" }
        let formatter = DateFormatter()
        formatter.timeZone = zone; formatter.dateFormat = "EEE, MMM d h:mm a"
        return formatter.string(from: date)
    }
}

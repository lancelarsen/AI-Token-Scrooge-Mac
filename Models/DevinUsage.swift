import Foundation

enum DevinUsage {
    static func workspace(_ input: String) -> URL? {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let address = value.contains("://") ? value : "https://" + value
        guard let parts = URLComponents(string: address), parts.scheme?.lowercased() == "https",
              parts.user == nil, parts.password == nil, parts.port == nil || parts.port == 443,
              let host = parts.host?.lowercased(),
              host.wholeMatch(of: /^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.devinenterprise\.com$/) != nil
        else { return nil }
        return URL(string: "https://" + host)
    }

    static func window(_ fields: [String], observed: Date) throws -> QuotaWindow {
        func amount(_ text: String) -> Decimal? {
            guard text.utf8.count <= 40, text.wholeMatch(of: /(?:[0-9]+|[0-9]{1,3}(?:,[0-9]{3})+)(?:\.[0-9]+)?/) != nil else { return nil }
            return Decimal(string: text.replacingOccurrences(of: ",", with: ""), locale: Locale(identifier: "en_US_POSIX"))
        }
        guard fields.count == 4, let used = amount(fields[0]) else {
            throw ProviderFailure(message: "Devin returned an unreadable ACU total.", health: .unsupported)
        }
        let limit = amount(fields[1])
        return QuotaWindow(id: "devin/monthly", name: "Monthly ACUs", unit: .acus, used: used, limit: limit,
                           resetsAt: reset(fields[2], zone: fields[3], observed: observed), durationMinutes: nil,
                           allowanceSource: limit == nil ? .unknown : .provider)
    }

    private static func reset(_ text: String, zone: String, observed: Date) -> Date? {
        guard let tz = TimeZone(identifier: zone),
              let parts = text.uppercased().wholeMatch(of: /([0-9]{1,2})\/([0-9]{1,2})\s+([0-9]{1,2}):([0-9]{2})\s*([AP]M)/),
              let month = Int(parts.1), let day = Int(parts.2), let hour = Int(parts.3), (1...12).contains(hour),
              let minute = Int(parts.4), (0...59).contains(minute), (1...12).contains(month), (1...31).contains(day)
        else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tz
        let match = DateComponents(month: month, day: day, hour: hour % 12 + (parts.5 == "PM" ? 12 : 0), minute: minute, second: 0)
        // Start before both occurrences of a repeated hour, even when one has already passed.
        let start = observed.addingTimeInterval(-86400)
        guard let first = calendar.nextDate(after: start, matching: match, matchingPolicy: .strict, repeatedTimePolicy: .first),
              first > observed, first.timeIntervalSince(observed) <= 32 * 86400,
              calendar.nextDate(after: start, matching: match, matchingPolicy: .strict, repeatedTimePolicy: .last) == first else { return nil }
        return first
    }

    static func historyColor(_ id: String) -> String {
        let hash = id.utf16.reduce(UInt32(2166136261)) { ($0 ^ UInt32($1)) &* 16777619 }
        let hue = Double(hash & 0xffffff) / 16777216 * 6
        let saturation = 0.48 + Double(hash >> 24) / 255 * 0.22
        let chroma = 0.56 * saturation
        let secondary = chroma * (1 - abs(hue.truncatingRemainder(dividingBy: 2) - 1))
        let channels = [[chroma, secondary, 0], [secondary, chroma, 0], [0, chroma, secondary],
                        [0, secondary, chroma], [secondary, 0, chroma], [chroma, 0, secondary]][Int(hue)]
        return "#" + channels.map { String(format: "%02X", Int((($0 + 0.72 - chroma / 2) * 255).rounded(.toNearestOrEven))) }.joined()
    }
}

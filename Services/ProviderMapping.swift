import Foundation

indirect enum JSONValue: Codable, Sendable, Equatable {
    case object([String: JSONValue]), array([JSONValue]), string(String), number(Decimal), bool(Bool), null
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let v = try? c.decode(Bool.self) { self = .bool(v) }
        else if let v = try? c.decode(Decimal.self) { self = .number(v) }
        else if let v = try? c.decode(String.self) { self = .string(v) }
        else if let v = try? c.decode([String: JSONValue].self) { self = .object(v) }
        else { self = .array(try c.decode([JSONValue].self)) }
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .object(let v): try c.encode(v)
        case .array(let v): try c.encode(v)
        case .string(let v): try c.encode(v)
        case .number(let v): try c.encode(v)
        case .bool(let v): try c.encode(v)
        case .null: try c.encodeNil()
        }
    }
    subscript(_ key: String) -> JSONValue { object?[key] ?? .null }
    var object: [String: JSONValue]? { if case .object(let v) = self { v } else { nil } }
    var array: [JSONValue]? { if case .array(let v) = self { v } else { nil } }
    var string: String? { if case .string(let v) = self { v } else { nil } }
    var number: Decimal? { if case .number(let v) = self { v } else { nil } }
    var bool: Bool? { if case .bool(let v) = self { v } else { nil } }
    var integer: Int? {
        guard let number, number >= 0, number <= Decimal(Int32.max) else { return nil }
        let value = NSDecimalNumber(decimal: number).intValue
        return Decimal(value) == number ? value : nil
    }
    var timestamp: Date? {
        guard let number, number >= -62135596800, number <= 253402300799 else { return nil }
        let value = NSDecimalNumber(decimal: number).doubleValue
        return value.rounded() == value ? Date(timeIntervalSince1970: value) : nil
    }
}

struct ProviderFailure: LocalizedError, Sendable {
    var message: String
    var health: SourceHealth = .offline
    var retryAt: Date?
    var errorDescription: String? { message }
}

enum ProviderMapping {
    static func codex(account: ProviderAccount, response: JSONValue, observed: Date) throws -> QuotaSnapshot {
        let scope = response["accountId"].string
        if let scope, !scope.isEmpty, account.scope != "unresolved", scope != account.scope { throw AccountError.differentIdentity }
        var windows: [QuotaWindow] = []
        func bucket(_ id: String, _ data: JSONValue) {
            for key in ["primary", "secondary"] {
                let window = data[key]
                guard window.object != nil else { continue }
                let minutes = window["windowDurationMins"].integer.flatMap { $0 == 0 ? nil : $0 }
                let duration = minutes == 300 ? "5-hour" : minutes == 10080 ? "Weekly" : minutes.map { "\($0) min" } ?? key
                let name = data["limitName"].string ?? (id == "codex" ? "Codex" : id)
                windows.append(QuotaWindow(id: "\(id)/\(key)", name: "\(name) · \(duration)", unit: .percent, used: window["usedPercent"].number, limit: 100, resetsAt: window["resetsAt"].timestamp, durationMinutes: minutes, allowanceSource: .provider))
            }
        }
        if let map = response["rateLimitsByLimitId"].object, !map.isEmpty {
            for key in map.keys.sorted() { bucket(key, map[key]!) }
        } else if response["rateLimits"].object != nil { bucket(response["rateLimits"]["limitId"].string ?? "codex", response["rateLimits"]) }
        var reserve: ResetReserve?
        if response["rateLimitResetCredits"].object != nil {
            let data = response["rateLimitResetCredits"]
            var seen = Set<String>()
            let details = try data["credits"].array?.compactMap { item -> ResetCredit? in
                guard let id = item["id"].string else { throw ProviderFailure(message: "Reset credit identity missing.") }
                guard seen.insert(id).inserted else { return nil }
                return ResetCredit(id: id, status: item["status"].string ?? "unknown", expiresAt: item["expiresAt"].timestamp, title: item["title"].string)
            }
            reserve = ResetReserve(availableCount: data["availableCount"].integer, credits: details)
        }
        let hasReserve = reserve?.availableCount != nil || !(reserve?.credits?.isEmpty ?? true)
        var message: String? = scope == nil ? "Workspace identity unavailable from provider" : nil
        if response["ordinaryUsageAllowed"].bool == false { message = "Provider reports included usage is paused" }
        if windows.isEmpty, hasReserve { message = "Codex reported reset credits; quota windows are unavailable." }
        return QuotaSnapshot(accountID: account.id, subject: account.subject, scope: scope ?? account.scope, observedAt: observed, windows: windows, reserve: reserve, health: windows.isEmpty && !hasReserve ? .unsupported : .healthy, message: message, usageAllowed: response["ordinaryUsageAllowed"].bool)
    }
    static func githubAllowance(_ response: JSONValue, unit: UsageUnit) -> Decimal? {
        guard let plan = response["copilot_plan"].string,
              ["individual", "individual_pro", "individual_max", "individual_edu"].contains(plan),
              let billing = response["token_based_billing"].bool,
              (billing ? UsageUnit.credits : .requests) == unit else { return nil }
        let quota = response["quota_snapshots"]["premium_interactions"]
        guard quota["unlimited"].bool == false else { return nil }
        let amount = quota["entitlement"].number ?? quota["entitlement"].string.flatMap(QuotaAmount.decimal)
        return amount.flatMap { $0 >= 0 ? $0 : nil }
    }
    static func github(account: ProviderAccount, response: JSONValue, observed: Date, allowance: Decimal? = nil) throws -> QuotaSnapshot {
        guard let items = response["usageItems"].array else { throw ProviderFailure(message: "Billing response did not include usage data.") }
        var total: Decimal = 0
        var matched = false
        var unknown = false
        for item in items {
            let unit = item["unitType"].string ?? ""
            if !["requests", "credits", "ai-credits"].contains(unit) { unknown = true }
            if account.unit == .requests ? unit == "requests" : ["credits", "ai-credits"].contains(unit) {
                guard let quantity = item["grossQuantity"].number, quantity >= 0 else { throw ProviderFailure(message: "Billing quantity is unavailable or invalid.") }
                total += quantity; matched = true
            }
        }
        let used: Decimal? = unknown || (!items.isEmpty && !matched) ? nil : total
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let month = calendar.date(from: calendar.dateComponents([.year, .month], from: observed))!
        let reset = calendar.date(byAdding: .month, value: 1, to: month)
        let window = QuotaWindow(id: "copilot/monthly", name: account.unit == .requests ? "Premium requests · Monthly" : "AI credits · Monthly", unit: account.unit, used: used, limit: allowance ?? account.allowance, resetsAt: reset, allowanceSource: allowance != nil ? .provider : account.allowance != nil ? .manual : .unknown)
        return QuotaSnapshot(accountID: account.id, subject: account.subject, scope: account.scope, observedAt: observed, windows: [window], message: used == nil ? "The report did not establish usage in the selected unit. Capacity is unavailable." : allowance != nil ? "Allowance reported by GitHub; billing usage may lag." : "Automatic allowance unavailable; a user-entered allowance is used when supplied. Billing reports may lag.")
    }
}

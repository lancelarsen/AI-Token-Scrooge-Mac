import Foundation

enum Provider: String, Codable, CaseIterable, Identifiable, Sendable {
    case codex = "OpenAI", copilot = "GitHub Copilot", claude = "Claude"
    var id: String { rawValue }
    var imageName: String { switch self { case .codex: "openai"; case .copilot: "github"; case .claude: "claude" } }
}

enum UsageUnit: String, Codable, Sendable { case percent, credits, requests }
enum SourceHealth: String, Codable, Sendable {
    case healthy, loading, stale, offline, authenticationRequired, permissionRequired, unsupported, demo
}
enum AllowanceProvenance: String, Codable, Sendable { case unknown, provider, manual }
enum CapacityState: String, Codable, Sendable { case unknown, healthy, info, low, critical, exhausted }

struct ProviderAccount: Codable, Identifiable, Equatable, Sendable {
    var id: String = UUID().uuidString
    var provider: Provider
    var nickname: String
    var subject: String
    var scope: String
    var enabled = true
    var allowance: Decimal?
    var unit: UsageUnit = .credits
    var login: String?
    var credentialID: String = UUID().uuidString
    var pollingMinutes = 2
    var lineColor: String = "#B5A0F4"
    var generation: UUID = UUID()
    var effectivePollingMinutes: Int { min(30, max(1, pollingMinutes)) }
    func scopeEquals(_ other: String) -> Bool {
        provider == .copilot ? scope.caseInsensitiveCompare(other) == .orderedSame : scope == other
    }
}

struct QuotaWindow: Codable, Identifiable, Equatable, Sendable {
    var id: String
    var name: String
    var unit: UsageUnit
    var used: Decimal?
    var limit: Decimal?
    var resetsAt: Date?
    var durationMinutes: Int?
    var allowanceSource: AllowanceProvenance = .unknown
    var usedPercent: Decimal? {
        guard let used, used >= 0 else { return nil }
        if unit == .percent { return used }
        guard let limit, limit > 0 else { return nil }
        return used / limit * 100
    }
    var remaining: Decimal? {
        guard let used, used >= 0 else { return nil }
        if unit == .percent { return max(0, 100 - used) }
        guard let limit, limit >= 0 else { return nil }
        return limit - used
    }
    var remainingPercent: Decimal? { usedPercent.map { min(100, max(0, 100 - $0)) } }
    var fill: Double { usedPercent.map { min(1, max(0, NSDecimalNumber(decimal: $0).doubleValue / 100)) } ?? 0 }
    func capacity(_ thresholds: AlertThresholds = .init()) -> CapacityState {
        guard let left = remainingPercent else { return .unknown }
        if left <= 0 { return .exhausted }
        if left <= thresholds.critical { return .critical }
        if left <= thresholds.warning { return .low }
        if left <= thresholds.info { return .info }
        return .healthy
    }
}

struct ResetCredit: Codable, Identifiable, Equatable, Sendable {
    var id: String
    var status: String
    var expiresAt: Date?
    var title: String?
}
struct ResetReserve: Codable, Equatable, Sendable {
    var availableCount: Int?
    var credits: [ResetCredit]?
    var hasPartialDetails: Bool { (availableCount ?? 0) > (credits?.filter { $0.status == "available" }.count ?? 0) }
    func earliestExpiry(after now: Date) -> Date? {
        guard availableCount != 0 else { return nil }
        return credits?.filter { $0.status == "available" }.compactMap(\.expiresAt).filter { $0 > now }.min()
    }
}
struct QuotaSnapshot: Codable, Equatable, Sendable {
    var accountID: String
    var subject: String
    var scope: String
    var observedAt: Date
    var windows: [QuotaWindow]
    var reserve: ResetReserve?
    var health: SourceHealth = .healthy
    var message: String?
    var providerDataAt: Date?
    var usageAllowed: Bool?
    var planType: String?
    func belongs(to account: ProviderAccount) -> Bool {
        accountID == account.id && subject == account.subject && (account.scope == "unresolved" || account.scopeEquals(scope))
    }
}

enum AccountPolicy {
    static func reconnect(original: ProviderAccount, replacement: ProviderAccount) throws -> ProviderAccount {
        guard original.id == replacement.id, original.provider == replacement.provider,
              original.subject == replacement.subject,
              original.scope == "unresolved" || original.scopeEquals(replacement.scope) else {
            throw AccountError.differentIdentity
        }
        var accepted = replacement
        accepted.enabled = original.enabled
        accepted.pollingMinutes = original.effectivePollingMinutes
        accepted.nickname = original.nickname
        accepted.lineColor = original.lineColor
        accepted.generation = UUID()
        return accepted
    }
    static func nextRefresh(snapshot: QuotaSnapshot, account: ProviderAccount, now: Date) -> Date {
        let ordinary = now.addingTimeInterval(Double(account.effectivePollingMinutes * 60))
        let boundaries = snapshot.windows.compactMap(\.resetsAt)
            + (snapshot.reserve?.credits?.filter { $0.status == "available" }.compactMap(\.expiresAt) ?? [])
        return boundaries.filter { $0 > now && $0 < ordinary }.min() ?? ordinary
    }
}
enum AccountError: LocalizedError { case differentIdentity
    var errorDescription: String? { "This is a different account or workspace. Reconnect the original account, or add a separate connection." }
}

import Foundation

actor GitHubClient {
    private static let session = GitHubTransport.session(requestTimeout: 40, resourceTimeout: 60)

    func get(_ path: String, token: String) async throws -> JSONValue {
        guard let url = URL(string: "https://api.github.com/" + path), url.host == "api.github.com", GitHubDeviceFlow.validSecret(token) else {
            throw ProviderFailure(message: "GitHub credentials are unavailable.", health: .authenticationRequired)
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        request.setValue("AITokenScrooge/0.1", forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2026-03-10", forHTTPHeaderField: "X-GitHub-Api-Version")
        let (bytes, response) = try await Self.session.bytes(for: request)
        defer { bytes.task.cancel() }
        guard let response = response as? HTTPURLResponse else { throw ProviderFailure(message: "GitHub returned an invalid response.") }
        let now = Date.now
        let retry = Self.retryAfter(response.value(forHTTPHeaderField: "Retry-After"), now: now)
        if response.statusCode == 429 || (response.statusCode == 403 && (retry != nil || response.value(forHTTPHeaderField: "X-RateLimit-Remaining") == "0")) {
            let reset = response.value(forHTTPHeaderField: "X-RateLimit-Reset").flatMap(Double.init).flatMap { $0.isFinite && $0 > 0 && $0 <= 253402300799 ? Date(timeIntervalSince1970: $0) : nil }
            throw ProviderFailure(message: "GitHub asked Scrooge to wait before refreshing.", health: .stale, retryAt: Self.retryDeadline(retry ?? reset, now: now))
        }
        if response.statusCode == 401 { throw ProviderFailure(message: "GitHub sign-in expired. Reconnect this account.", health: .authenticationRequired) }
        if [403,404].contains(response.statusCode) { throw ProviderFailure(message: "GitHub billing access is unavailable. Personal tokens need Plan read permission; organization billing needs authorized administration access.", health: .permissionRequired) }
        guard (200..<300).contains(response.statusCode) else { throw ProviderFailure(message: "GitHub usage is temporarily unavailable. Last known values are retained.") }
        let data = try await GitHubTransport.body(bytes, response: response, limit: 5_000_000,
                                                  sizeError: "GitHub report exceeded the monitor's size limit.")
        return try JSONDecoder().decode(JSONValue.self, from: data)
    }
    nonisolated static func retryDeadline(_ reported: Date?, now: Date) -> Date {
        if let reported, reported > now { return reported }
        return now.addingTimeInterval(300)
    }
    nonisolated static func retryAfter(_ header: String?, now: Date) -> Date? {
        guard let value = header?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        if let seconds = Double(value), seconds.isFinite, seconds >= 0 {
            let date = now.addingTimeInterval(seconds)
            return date.timeIntervalSince1970.isFinite ? date : nil
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        formatter.isLenient = false
        return formatter.date(from: value)
    }
    func identify(token: String) async throws -> (subject: String, login: String) {
        let user = try await get("user", token: token)
        guard let id = user["id"].number, id > 0,
              let login = user["login"].string, !login.isEmpty else { throw ProviderFailure(message: "GitHub did not return an account identity.") }
        return (NSDecimalNumber(decimal: id).stringValue, login)
    }
    func read(account: ProviderAccount, token: String) async throws -> QuotaSnapshot {
        let identity = try await identify(token: token)
        guard identity.subject == account.subject else { throw AccountError.differentIdentity }
        let now = Date.now
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let kind = account.unit == .requests ? "premium_request" : "ai_credit"
        let escape: (String) -> String = { $0.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "" }
        let query = "year=\(calendar.component(.year, from: now))&month=\(calendar.component(.month, from: now))"
        let path = account.scope.hasPrefix("organization:")
            ? "organizations/\(escape(String(account.scope.dropFirst(13))))/settings/billing/\(kind)/usage?\(query)&user=\(escape(identity.login))"
            : "users/\(escape(identity.login))/settings/billing/\(kind)/usage?\(query)"
        let report = try await get(path, token: token)
        var allowance: Decimal?
        var plan: String?
        if account.scope == "personal" {
            do {
                let entitlement = try await get("copilot_internal/user", token: token)
                allowance = ProviderMapping.githubAllowance(entitlement, unit: account.unit)
                plan = entitlement["copilot_plan"].string
            } catch let error as ProviderFailure where error.retryAt != nil || error.health == .authenticationRequired { throw error }
            catch is CancellationError { throw CancellationError() }
            catch {
                // URLSession can report task cancellation as URLError.cancelled.
                try Task.checkCancellation()
                // Other failures of the optional allowance leave the billing report usable.
            }
        }
        var snapshot = try ProviderMapping.github(account: account, response: report, observed: now, allowance: allowance)
        snapshot.planType = plan
        return snapshot
    }
}

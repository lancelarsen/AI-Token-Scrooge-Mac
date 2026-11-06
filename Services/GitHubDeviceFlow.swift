import Foundation

struct GitHubAppTokens: Codable, Sendable {
    var clientID: String
    var accessToken: String
    var refreshToken: String
    var expiresAt: Date
    var refreshExpiresAt: Date
}
struct GitHubChallenge: Sendable {
    let clientID: String
    fileprivate let deviceCode: String
    let userCode: String
    let expiresAt: Date
    fileprivate let deadline: ContinuousClock.Instant
    fileprivate let interval: Int
    var verificationURL: URL { URL(string: "https://github.com/login/device")! }
}
actor GitHubDeviceFlow {
    private static let session = GitHubTransport.session(requestTimeout: 35, resourceTimeout: 35)

    nonisolated static func validClientID(_ value: String) -> Bool {
        !value.isEmpty && value.count <= 128 && value.range(of: #"\A[A-Za-z0-9_.-]+\z"#, options: .regularExpression) != nil
    }
    nonisolated static func validSecret(_ value: String) -> Bool {
        !value.isEmpty && value.utf8.count <= 4096 && value.utf8.allSatisfy { $0 >= 33 && $0 <= 126 }
    }
    nonisolated static func reconnect() -> ProviderFailure { ProviderFailure(message: "Reconnect GitHub to restore monitoring.", health: .authenticationRequired) }
    func begin() async throws -> GitHubChallenge {
        guard let url = Bundle.main.url(forResource: "github-app", withExtension: "json"),
              let config = try? JSONDecoder().decode(JSONValue.self, from: Data(contentsOf: url)),
              let clientID = config["clientId"].string, Self.validClientID(clientID) else {
            throw ProviderFailure(message: "GitHub browser sign-in is not configured in this build.", health: .unsupported)
        }
        let started = ContinuousClock.now; let now = Date.now
        let result = try await post("/login/device/code", fields: ["client_id": clientID, "scope": "offline_access"])
        try Self.checkError(result)
        guard result["verification_uri"].string == "https://github.com/login/device",
              let code = result["user_code"].string, code.range(of: #"\A[A-Z0-9]{4}-[A-Z0-9]{4}\z"#, options: .regularExpression) != nil,
              let device = result["device_code"].string, Self.validSecret(device) else { throw ProviderFailure(message: "GitHub returned an invalid sign-in request. Try again.") }
        let lifetime = try Self.number(result, "expires_in", range: 1...1800)
        let interval = result.object?["interval"] == nil ? 5 : try Self.number(result, "interval", range: 1...300)
        return GitHubChallenge(clientID: clientID, deviceCode: device, userCode: code, expiresAt: now.addingTimeInterval(Double(lifetime)), deadline: started.advanced(by: .seconds(lifetime)), interval: interval)
    }
    func wait(_ challenge: GitHubChallenge) async throws -> GitHubAppTokens {
        var interval = challenge.interval
        while true {
            try Task.checkCancellation()
            guard ContinuousClock.now.advanced(by: .seconds(interval)) < challenge.deadline else { throw Self.expired() }
            try await Task.sleep(for: .seconds(interval))
            guard ContinuousClock.now < challenge.deadline else { throw Self.expired() }
            let result = try await post("/login/oauth/access_token", fields: ["client_id": challenge.clientID, "device_code": challenge.deviceCode, "grant_type": "urn:ietf:params:oauth:grant-type:device_code"])
            switch result["error"].string {
            case "authorization_pending": continue
            case "slow_down": interval = max(interval + 5, result["interval"].integer.flatMap { (1...1800).contains($0) ? $0 : nil } ?? 0)
            default: try Self.checkError(result); return try Self.tokens(result, clientID: challenge.clientID, now: .now)
            }
        }
    }
    func refresh(_ previous: GitHubAppTokens) async throws -> GitHubAppTokens {
        guard Self.validClientID(previous.clientID), Self.validSecret(previous.refreshToken) else { throw Self.reconnect() }
        let result = try await post("/login/oauth/access_token", fields: ["client_id": previous.clientID, "grant_type": "refresh_token", "refresh_token": previous.refreshToken])
        try Self.checkError(result)
        return try Self.tokens(result, clientID: previous.clientID, now: .now)
    }
    nonisolated static func tokens(_ value: JSONValue, clientID: String, now: Date) throws -> GitHubAppTokens {
        guard validClientID(clientID), let access = value["access_token"].string, validSecret(access),
              let refresh = value["refresh_token"].string, validSecret(refresh), value["token_type"].string?.lowercased() == "bearer" else {
            throw ProviderFailure(message: "GitHub returned incomplete sign-in credentials. Sign in again.", health: .authenticationRequired)
        }
        return GitHubAppTokens(clientID: clientID, accessToken: access, refreshToken: refresh,
            expiresAt: now.addingTimeInterval(Double(try number(value, "expires_in", range: 1...86400))),
            refreshExpiresAt: now.addingTimeInterval(Double(try number(value, "refresh_token_expires_in", range: 1...(366 * 86400)))))
    }
    private func post(_ path: String, fields: [String: String]) async throws -> JSONValue {
        var request = URLRequest(url: URL(string: "https://github.com" + path)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("AITokenScrooge/0.1", forHTTPHeaderField: "User-Agent")
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        request.httpBody = Data(fields.keys.sorted().map { key in
            "\(key.addingPercentEncoding(withAllowedCharacters: allowed)!)=\(fields[key]!.addingPercentEncoding(withAllowedCharacters: allowed)!)"
        }.joined(separator: "&").utf8)
        let (bytes, response) = try await Self.session.bytes(for: request)
        defer { bytes.task.cancel() }
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw ProviderFailure(message: "GitHub sign-in is temporarily unavailable. Try again.") }
        let data = try await GitHubTransport.body(bytes, response: response, limit: 65_536,
                                                  sizeError: "GitHub sign-in response exceeded the size limit.")
        guard let result = try? JSONDecoder().decode(JSONValue.self, from: data), result.object != nil else { throw ProviderFailure(message: "GitHub returned an invalid sign-in response. Try again.") }
        return result
    }
    private nonisolated static func number(_ value: JSONValue, _ key: String, range: ClosedRange<Int>) throws -> Int {
        guard let number = value[key].integer, range.contains(number) else { throw ProviderFailure(message: "GitHub returned invalid sign-in timing. Try again.") }
        return number
    }
    private nonisolated static func expired() -> ProviderFailure { ProviderFailure(message: "The GitHub sign-in code expired. Start sign-in again.", health: .authenticationRequired) }
    private nonisolated static func checkError(_ value: JSONValue) throws {
        guard let error = value["error"].string else { return }
        let message: String
        switch error {
        case "access_denied": message = "GitHub sign-in was declined. You can try again."
        case "expired_token", "token_expired": throw expired()
        case "device_flow_disabled", "incorrect_client_credentials": message = "GitHub browser sign-in needs the app registration configured by Scrooge's developer."
        case "bad_refresh_token": throw reconnect()
        default: message = "GitHub could not complete sign-in. Try again."
        }
        throw ProviderFailure(message: message, health: .authenticationRequired)
    }
}

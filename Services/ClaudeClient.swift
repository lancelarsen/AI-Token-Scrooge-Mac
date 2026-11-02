import Foundation

actor ClaudeClient {
    static func executable() throws -> URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let candidates = [home.appendingPathComponent(".local/bin/claude"), URL(fileURLWithPath: "/opt/homebrew/bin/claude"), URL(fileURLWithPath: "/usr/local/bin/claude")]
        guard let executable = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0.path) }) else {
            throw ProviderFailure(message: "Install Claude Code to connect a Claude account.", health: .unsupported)
        }
        return executable
    }
    private func profile(_ id: String) throws -> URL {
        guard let uuid = UUID(uuidString: id) else { throw SecretStoreError.invalidID }
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AI Token Scrooge/ClaudeProfiles/\(uuid.uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        return url
    }
    private func run(_ id: String, _ arguments: [String], timeout: Duration = .seconds(40)) async throws -> Data {
        let directory = try profile(id)
        var environment = ProcessInfo.processInfo.environment.filter { !$0.key.uppercased().hasPrefix("ANTHROPIC_") && !$0.key.uppercased().hasPrefix("CLAUDE_") }
        environment["CLAUDE_CONFIG_DIR"] = directory.path
        return try await BoundedProcess().run(executable: Self.executable(), arguments: arguments, directory: directory, environment: environment, timeout: timeout)
    }
    private func identity(_ credentialID: String) async throws -> (subject: String, scope: String, plan: String) {
        let value = try JSONDecoder().decode(JSONValue.self, from: await run(credentialID, ["auth", "status"]))
        guard value["loggedIn"].bool == true, value["authMethod"].string == "claude.ai",
              let email = value["email"].string, !email.isEmpty, let scope = value["orgId"].string, !scope.isEmpty else {
            throw ProviderFailure(message: "Sign in with your Claude subscription account.", health: .authenticationRequired)
        }
        return (email.lowercased(), scope, value["subscriptionType"].string ?? "unknown")
    }
    func connect(credentialID: String, nickname: String, original: ProviderAccount?) async throws -> (ProviderAccount, QuotaSnapshot) {
        _ = try await run(credentialID, ["auth", "login"], timeout: .seconds(600))
        let identity = try await identity(credentialID)
        var account = ProviderAccount(provider: .claude, nickname: nickname, subject: identity.subject, scope: identity.scope, login: identity.subject, credentialID: credentialID)
        if let original { account.id = original.id; account = try AccountPolicy.reconnect(original: original, replacement: account) }
        return (account, try await usage(account, plan: identity.plan))
    }
    func refresh(_ account: ProviderAccount) async throws -> QuotaSnapshot {
        let identity = try await identity(account.credentialID)
        guard identity.subject == account.subject, identity.scope == account.scope else { throw AccountError.differentIdentity }
        return try await usage(account, plan: identity.plan)
    }
    func disconnect(_ credentialID: String) async throws { _ = try await run(credentialID, ["auth", "logout"]) }
    private func usage(_ account: ProviderAccount, plan: String) async throws -> QuotaSnapshot {
        let version = String(decoding: try await run(account.credentialID, ["--version"]), as: UTF8.self)
        guard Self.supportsUsage(version) else { throw ProviderFailure(message: "Update Claude Code to version 2.1.310 or later to read usage in Scrooge.", health: .unsupported) }
        // Only the supported quota command is permitted; there is no prompt/inference fallback.
        let screen = String(decoding: try await run(account.credentialID, ["/usage"]), as: UTF8.self)
        let now = Date.now
        let windows = ClaudeUsageParser.parse(screen, now: now)
        guard !windows.isEmpty else { throw ProviderFailure(message: "Claude Code did not return readable usage limits. Check Claude's Usage page.", health: .unsupported) }
        return QuotaSnapshot(accountID: account.id, subject: account.subject, scope: account.scope, observedAt: now, windows: windows,
            message: "Read from Claude Code. Reset times are shown to the nearest minute; reset credits are not supplied by this source.", planType: plan)
    }
    nonisolated static func supportsUsage(_ text: String) -> Bool {
        guard let first = text.split(whereSeparator: \.isWhitespace).first else { return false }
        let components = first.split(separator: ".").compactMap { Int($0) }
        guard components.count >= 3 else { return false }
        return !components.prefix(3).lexicographicallyPrecedes([2, 1, 310])
    }
}

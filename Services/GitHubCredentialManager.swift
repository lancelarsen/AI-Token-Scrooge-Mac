import Foundation

actor GitHubCredentialManager {
    private struct Envelope: Codable, Sendable {
        var version = 1
        var subject: String
        var tokens: GitHubAppTokens
        var needsVerification = false
        var renewalStarted = false
    }
    private static let prefix = "github-app:v1:"
    struct Dependencies: Sendable {
        var read: @Sendable (String) async throws -> Data?
        var save: @Sendable (Data, String) async throws -> Void
        var remove: @Sendable (String) async throws -> Void
        var refresh: @Sendable (GitHubAppTokens) async throws -> GitHubAppTokens
        var identify: @Sendable (String) async throws -> String
    }
    private let dependencies: Dependencies
    private var pending: [String: Envelope] = [:]
    private var gates: [String: Task<Void, Never>] = [:]
    init(secrets: SecretStore, usage: GitHubClient) {
        let flow = GitHubDeviceFlow()
        dependencies = Dependencies(read: { try await secrets.read($0) },
            save: { try await secrets.save($0, id: $1) }, remove: { try await secrets.remove($0) },
            refresh: { try await flow.refresh($0) }, identify: { try await usage.identify(token: $0).subject })
    }
    init(dependencies: Dependencies) { self.dependencies = dependencies }
    func saveApp(id: String, subject: String, tokens: GitHubAppTokens) async throws {
        let record = Envelope(subject: subject, tokens: tokens)
        try validate(record)
        try await dependencies.save(encode(record), id)
    }
    func accessToken(for account: ProviderAccount) async throws -> String {
        let prior = gates[account.credentialID]
        let work = Task { [self] in
            await prior?.value
            return try await read(account)
        }
        gates[account.credentialID] = Task { _ = try? await work.value }
        // Once rotation starts it must finish or leave a durable reconnect marker, even if its caller disappears.
        return try await work.value
    }
    private func read(_ account: ProviderAccount) async throws -> String {
        let id = account.credentialID
        if let replacement = pending[id] { try await persistReplacement(replacement, id: id) }
        guard let data = try await dependencies.read(id), data.count <= 32768, let saved = String(data: data, encoding: .utf8) else { throw GitHubDeviceFlow.reconnect() }
        guard saved.hasPrefix(Self.prefix) else {
            guard !saved.hasPrefix("github-app:"), !saved.hasPrefix("{"), GitHubDeviceFlow.validSecret(saved) else { throw GitHubDeviceFlow.reconnect() }
            return saved
        }
        guard var record = try? JSONDecoder().decode(Envelope.self, from: Data(saved.dropFirst(Self.prefix.count).utf8)) else { throw GitHubDeviceFlow.reconnect() }
        try validate(record)
        guard record.subject == account.subject, !record.renewalStarted else { throw GitHubDeviceFlow.reconnect() }
        if record.tokens.expiresAt <= Date.now.addingTimeInterval(120) {
            guard record.tokens.refreshExpiresAt > .now else { throw GitHubDeviceFlow.reconnect() }
            var intent = record; intent.renewalStarted = true
            try await dependencies.save(encode(intent), id)
            let tokens = try await dependencies.refresh(record.tokens)
            record.tokens = tokens; record.needsVerification = true; record.renewalStarted = false
            pending[id] = record
            try await persistReplacement(record, id: id)
        }
        if record.needsVerification {
            let identity = try await dependencies.identify(record.tokens.accessToken)
            guard identity == account.subject else { throw GitHubDeviceFlow.reconnect() }
            record.needsVerification = false
            try await dependencies.save(encode(record), id)
        }
        return record.tokens.accessToken
    }
    func remove(_ id: String) async throws {
        let prior = gates[id]
        let work = Task { [self] in
            await prior?.value
            try await dependencies.remove(id)
            pending.removeValue(forKey: id)
        }
        gates[id] = Task { _ = try? await work.value }
        try await work.value
    }
    private func persistReplacement(_ record: Envelope, id: String) async throws {
        do { try await dependencies.save(encode(record), id); pending.removeValue(forKey: id) }
        catch { throw ProviderFailure(message: "macOS could not save the renewed GitHub sign-in. Retry refresh before closing Scrooge.", health: .stale) }
    }
    private func encode(_ record: Envelope) throws -> Data {
        var result = Data(Self.prefix.utf8); result.append(try JSONEncoder().encode(record)); return result
    }
    private func validate(_ record: Envelope) throws {
        guard record.version == 1, !record.subject.isEmpty, GitHubDeviceFlow.validClientID(record.tokens.clientID),
              GitHubDeviceFlow.validSecret(record.tokens.accessToken), GitHubDeviceFlow.validSecret(record.tokens.refreshToken),
              record.tokens.expiresAt.timeIntervalSince1970.isFinite, record.tokens.refreshExpiresAt.timeIntervalSince1970.isFinite else { throw GitHubDeviceFlow.reconnect() }
    }
}

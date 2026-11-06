import Foundation

/// A quota-only protocol client. No inference or credit-redemption method is exposed.
actor CodexConnection {
    static let allowed: Set<String> = ["initialize", "account/read", "account/rateLimits/read", "account/login/start", "account/login/cancel", "account/logout"]
    nonisolated let notifications: AsyncStream<JSONValue>
    private let notificationContinuation: AsyncStream<JSONValue>.Continuation
    private let process: Process
    private let input: FileHandle
    private var reader: (any DispatchSourceRead)?
    private var pending: [Int: CheckedContinuation<JSONValue, Error>] = [:]
    private var deadlines: [Int: Task<Void, Never>] = [:]
    private var nextID = 0
    private var ended = false
    private var buffer = Data()

    private init(process: Process, input: FileHandle) {
        self.process = process; self.input = input
        let pair = AsyncStream<JSONValue>.makeStream(bufferingPolicy: .bufferingNewest(16))
        notifications = pair.stream; notificationContinuation = pair.continuation
    }
    static func profileURL(id: String) throws -> URL {
        guard let uuid = UUID(uuidString: id) else { throw SecretStoreError.invalidID }
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AI Token Scrooge/Profiles/\(uuid.uuidString)", isDirectory: true)
    }
    // The desktop CLI reports earned reset credits on accounts where older
    // standalone releases return only the ordinary quota windows.
    static var installedExecutables: [URL] {
        let desktop = URL(fileURLWithPath: "/Applications/Codex.app/Contents/Resources")
        let candidates = [
            desktop.appendingPathComponent("codex-cli/CodexCLI.app/Contents/MacOS/codex"),
            desktop.appendingPathComponent("codex"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".local/bin/codex"),
            URL(fileURLWithPath: "/opt/homebrew/bin/codex"),
            URL(fileURLWithPath: "/usr/local/bin/codex")
        ]
        return candidates.filter { FileManager.default.isExecutableFile(atPath: $0.path) }
    }
    static func executable() throws -> URL {
        guard let found = installedExecutables.first else {
            throw ProviderFailure(message: "Install the Codex desktop app or CLI to connect an OpenAI account.", health: .unsupported)
        }
        return found
    }
    static func start(credentialID: String) async throws -> CodexConnection {
        let profile = try OwnedProfileDirectory.directory(provider: .codex, id: credentialID)
        let process = Process()
        process.executableURL = try executable()
        process.currentDirectoryURL = profile
        var env = CLIEnvironment.sanitized(ProcessInfo.processInfo.environment)
        env["CODEX_HOME"] = profile.path
        process.environment = env
        process.arguments = ["app-server", "--stdio", "-c", "cli_auth_credentials_store=\"keyring\"", "-c", "mcp_servers={}", "-c", "analytics.enabled=false"]
        let input = try Pipe.commandInput()
        let output = Pipe()
        process.standardInput = input
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        let connection = CodexConnection(process: process, input: input.fileHandleForWriting)
        try process.run()
        await connection.beginReading(output)
        do {
            _ = try await connection.call("initialize", parameters: .object([
                "clientInfo": .object(["name": .string("ai_reset_radar"), "title": .string("AI Token Scrooge"), "version": .string(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "development")]),
                "capabilities": .object(["experimentalApi": .bool(true)])]))
            try await connection.write(.object(["method": .string("initialized")]))
            return connection
        } catch { await connection.close(); throw error }
    }
    private func beginReading(_ output: Pipe) {
        reader = output.readCommandOutput { [weak self] data in
            await self?.receive(data)
        }
    }
    func call(_ method: String, parameters: JSONValue = .null) async throws -> JSONValue {
        guard Self.allowed.contains(method) else { throw ProviderFailure(message: "This method is not allowed by the usage monitor.", health: .unsupported) }
        guard !ended else { throw ProviderFailure(message: "Codex connection ended. Reconnect to continue monitoring.") }
        try Task.checkCancellation()
        nextID += 1
        let id = nextID
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                pending[id] = continuation
                deadlines[id] = Task { [weak self] in
                    do { try await Task.sleep(for: .seconds(40)) } catch { return }
                    await self?.fail(id, error: ProviderFailure(message: "Codex did not respond in time. Please retry."))
                }
                do { try write(.object(["id": .number(Decimal(id)), "method": .string(method), "params": parameters])) }
                catch {
                    fail(id, error: error)
                    close()
                }
            }
        } onCancel: { Task { await self.fail(id, error: CancellationError()) } }
    }
    private func write(_ message: JSONValue) throws {
        var data = try JSONEncoder().encode(message); data.append(10)
        try input.writeCommand(data)
    }
    private func receive(_ data: Data) {
        guard !ended else { return }
        guard !data.isEmpty else { close(); return }
        buffer.append(data)
        do {
            while let end = buffer.firstIndex(of: 10) {
                guard end <= 2_000_000 else { throw ProviderFailure(message: "Codex response exceeded the monitor's size limit.") }
                let line = Data(buffer[..<end]); buffer.removeSubrange(...end)
                if line.isEmpty { continue }
                let response = try JSONDecoder().decode(JSONValue.self, from: line)
                guard response.object != nil else { throw ProviderFailure(message: "Codex returned an invalid protocol response.") }
                if let id = response["id"].integer, let completion = pending.removeValue(forKey: id) {
                    deadlines.removeValue(forKey: id)?.cancel()
                    if response.object?["error"] != nil { completion.resume(throwing: ProviderFailure(message: "Codex could not complete this monitoring request. Check sign-in and retry.")) }
                    else { completion.resume(returning: response["result"]) }
                } else if response["method"].string != nil { notificationContinuation.yield(response) }
            }
            guard buffer.count <= 2_000_000 else { throw ProviderFailure(message: "Codex response exceeded the monitor's size limit.") }
        } catch { close() }
    }
    private func fail(_ id: Int, error: Error) {
        deadlines.removeValue(forKey: id)?.cancel()
        pending.removeValue(forKey: id)?.resume(throwing: error)
    }
    func close() {
        guard !ended else { return }
        ended = true
        notificationContinuation.finish()
        try? input.close()
        process.stopWithDeadline()
        for id in Array(pending.keys) { fail(id, error: ProviderFailure(message: "Codex connection ended. Reconnect to continue monitoring.")) }
        reader?.cancel(); reader = nil
    }
    func snapshot(account: ProviderAccount) async throws -> QuotaSnapshot {
        let identity = try await call("account/read", parameters: .object(["refreshToken": .bool(false)]))
        guard identity["account"]["email"].string == account.subject else { throw AccountError.differentIdentity }
        var snapshot = try ProviderMapping.codex(account: account, response: await call("account/rateLimits/read"), observed: .now)
        snapshot.planType = identity["account"]["planType"].string
        return snapshot
    }
}

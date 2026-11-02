import Foundation

/// A quota-only protocol client. No inference or credit-redemption method is exposed.
actor CodexConnection {
    static let allowed: Set<String> = ["initialize", "account/read", "account/rateLimits/read", "account/login/start", "account/login/cancel", "account/logout"]
    nonisolated let notifications: AsyncStream<JSONValue>
    private let notificationContinuation: AsyncStream<JSONValue>.Continuation
    private let process: Process
    private let input: FileHandle
    private var reader: Task<Void, Never>?
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
    static func executable() throws -> URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let candidates = [home.appendingPathComponent(".local/bin/codex"),
                          URL(fileURLWithPath: "/opt/homebrew/bin/codex"),
                          URL(fileURLWithPath: "/usr/local/bin/codex"),
                          URL(fileURLWithPath: "/Applications/Codex.app/Contents/Resources/codex")]
        guard let found = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0.path) }) else {
            throw ProviderFailure(message: "Install the Codex desktop app or CLI to connect an OpenAI account.", health: .unsupported)
        }
        return found
    }
    static func start(credentialID: String) async throws -> CodexConnection {
        let profile = try profileURL(id: credentialID)
        try FileManager.default.createDirectory(at: profile, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let process = Process()
        process.executableURL = try executable()
        process.currentDirectoryURL = profile
        var env = ProcessInfo.processInfo.environment.filter { !$0.key.uppercased().hasPrefix("CODEX_") && !$0.key.uppercased().hasPrefix("OPENAI_") }
        env["CODEX_HOME"] = profile.path
        process.environment = env
        process.arguments = ["app-server", "--stdio", "-c", "cli_auth_credentials_store=\"keyring\"", "-c", "mcp_servers={}", "-c", "analytics.enabled=false"]
        let input = Pipe(), output = Pipe(), errors = Pipe()
        process.standardInput = input; process.standardOutput = output; process.standardError = errors
        let connection = CodexConnection(process: process, input: input.fileHandleForWriting)
        try process.run()
        let stream = AsyncStream<Data> { continuation in
            DispatchQueue(label: "scrooge.codex.output").async {
                defer { continuation.finish(); try? output.fileHandleForReading.close() }
                while true {
                    let data = output.fileHandleForReading.availableData
                    if data.isEmpty { break }
                    continuation.yield(data)
                }
            }
        }
        DispatchQueue(label: "scrooge.codex.errors").async {
            defer { try? errors.fileHandleForReading.close() }
            while true {
                let data = errors.fileHandleForReading.availableData
                if data.isEmpty { break }
                /* Never log auth/provider output. */
            }
        }
        await connection.beginReading(stream)
        do {
            _ = try await connection.call("initialize", parameters: .object([
                "clientInfo": .object(["name": .string("ai_reset_radar"), "title": .string("AI Token Scrooge"), "version": .string("0.1.0")]),
                "capabilities": .object(["experimentalApi": .bool(true)])]))
            try await connection.write(.object(["method": .string("initialized")]))
            return connection
        } catch { await connection.close(); throw error }
    }
    private func beginReading(_ stream: AsyncStream<Data>) {
        reader = Task { [weak self] in
            for await chunk in stream {
                guard let self else { return }
                await self.receive(chunk)
            }
            await self?.close()
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
                catch { fail(id, error: error) }
            }
        } onCancel: { Task { await self.fail(id, error: CancellationError()) } }
    }
    private func write(_ message: JSONValue) throws {
        var data = try JSONEncoder().encode(message); data.append(10)
        try input.write(contentsOf: data)
    }
    private func receive(_ data: Data) {
        guard !ended else { return }
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

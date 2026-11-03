import Foundation
import Darwin

/// Owns a single bounded CLI operation, drains stderr without retaining secrets, and cancels its process.
actor BoundedProcess {
    private let process: Process
    init(process: Process = Process()) { self.process = process }
    private var output = Data()
    private var completion: CheckedContinuation<Data, Error>?
    private var exited: Int32?
    private var outputFinished = false
    private var stopped = false
    private var timer: Task<Void, Never>?
    func run(executable: URL, arguments: [String], directory: URL, environment: [String: String], timeout: Duration = .seconds(40)) async throws -> Data {
        try Task.checkCancellation()
        process.executableURL = executable; process.arguments = arguments
        process.currentDirectoryURL = directory; process.environment = environment
        let stdout = Pipe(), stderr = Pipe()
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = stdout; process.standardError = stderr
        process.terminationHandler = { [weak self] process in Task { await self?.didExit(process.terminationStatus) } }
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                completion = continuation
                do {
                    try process.run()
                    let stream = AsyncStream<Data> { continuation in
                        DispatchQueue(label: "scrooge.cli.stdout").async {
                            defer { continuation.finish(); try? stdout.fileHandleForReading.close() }
                            while true {
                                let data = stdout.fileHandleForReading.availableData
                                if data.isEmpty { break }; continuation.yield(data)
                            }
                        }
                    }
                    Task { [weak self] in
                        for await data in stream { await self?.append(data) }
                        await self?.finishedOutput()
                    }
                    DispatchQueue(label: "scrooge.cli.stderr").async {
                        defer { try? stderr.fileHandleForReading.close() }
                        while !stderr.fileHandleForReading.availableData.isEmpty { }
                    }
                    timer = Task { [weak self] in
                        do { try await Task.sleep(for: timeout) } catch { return }
                        await self?.fail(ProviderFailure(message: "The provider command timed out. Please try again."))
                    }
                } catch { fail(ProviderFailure(message: "The provider CLI could not start. Check its installation.", health: .unsupported)) }
            }
        } onCancel: { Task { await self.fail(CancellationError()) } }
    }
    private func append(_ data: Data) {
        guard !stopped else { return }
        guard output.count + data.count <= 2_000_000 else { fail(ProviderFailure(message: "Provider output exceeded the monitor's size limit.")); return }
        output.append(data)
    }
    private func didExit(_ status: Int32) { exited = status; completeIfReady() }
    private func finishedOutput() { outputFinished = true; completeIfReady() }
    private func completeIfReady() {
        guard !stopped, outputFinished, let exited else { return }
        if exited != 0 { fail(ProviderFailure(message: "Provider sign-in could not be confirmed. Reconnect this account.", health: .authenticationRequired)); return }
        stopped = true; timer?.cancel(); completion?.resume(returning: output); completion = nil
    }
    private func fail(_ error: Error) {
        guard !stopped else { return }
        stopped = true; timer?.cancel()
        process.stopWithDeadline()
        completion?.resume(throwing: error); completion = nil
    }
}

extension Process {
    /// Give the owned child time to exit, then enforce cleanup if it ignores SIGTERM.
    func stopWithDeadline() {
        guard isRunning else { return }
        terminate()
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 2) { [self] in
            if isRunning { _ = Darwin.kill(processIdentifier, SIGKILL) }
        }
    }
}


/// Remove inherited provider credentials and runtime injection hooks before starting owned CLIs.
/// Keep ordinary OS settings (PATH, locale, HOME) so installed provider tools remain usable.
enum CLIEnvironment {
    static func sanitized(_ environment: [String: String]) -> [String: String] {
        let prefixes = ["OPENAI_", "CODEX_", "ANTHROPIC_", "CLAUDE_", "GITHUB_", "GH_", "AZURE_OPENAI_", "GEMINI_", "DYLD_"]
        let excluded: Set<String> = ["GOOGLE_API_KEY", "GOOGLE_APPLICATION_CREDENTIALS", "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN", "AWS_PROFILE", "AWS_SHARED_CREDENTIALS_FILE", "AWS_CONFIG_FILE", "NODE_OPTIONS", "NODE_PATH", "BUN_OPTIONS", "LD_PRELOAD", "LD_LIBRARY_PATH"]
        return environment.filter { key, _ in
            let upper = key.uppercased()
            return !excluded.contains(upper) && !prefixes.contains(where: upper.hasPrefix)
        }
    }
}

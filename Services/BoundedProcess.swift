import Foundation

/// Owns a single bounded CLI operation, drains stderr without retaining secrets, and cancels its process.
actor BoundedProcess {
    private let process = Process()
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
        if process.isRunning { process.terminate() }
        completion?.resume(throwing: error); completion = nil
    }
}

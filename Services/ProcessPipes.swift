import Darwin
import Foundation

extension Pipe {
    /// A child can exit between its parent's liveness check and a protocol write.
    /// Deliver a write error to the caller without altering the app's signal handlers.
    static func commandInput() throws -> Pipe {
        let pipe = Pipe()
        let descriptor = pipe.fileHandleForWriting.fileDescriptor
        let flags = fcntl(descriptor, F_GETFL)
        guard flags != -1, fcntl(descriptor, F_SETFL, flags | O_NONBLOCK) != -1,
              fcntl(descriptor, F_SETNOSIGPIPE, 1) != -1 else {
            throw ProviderFailure(message: "The provider command pipe could not be opened.")
        }
        return pipe
    }

    /// Deliver one available chunk at a time. The pipe applies backpressure while the
    /// consumer processes the chunk. An empty chunk signals EOF.
    func readCommandOutput(_ receive: @escaping @Sendable (Data) async -> Void) -> any DispatchSourceRead {
        let handle = fileHandleForReading
        let source = DispatchSource.makeReadSource(fileDescriptor: handle.fileDescriptor, queue: .global(qos: .utility))
        source.setCancelHandler { try? handle.close() }
        source.setEventHandler {
            let chunk = handle.availableData
            if chunk.isEmpty {
                source.cancel()
                Task { await receive(chunk) }
            } else {
                source.suspend()
                Task {
                    await receive(chunk)
                    source.resume()
                }
            }
        }
        source.activate()
        return source
    }
}

extension FileHandle {
    /// The caller closes the protocol connection on a partial write. Waiting here
    /// for a stalled child would also block the actor handling cancellation.
    func writeCommand(_ data: Data) throws {
        let written = data.withUnsafeBytes { bytes in
            var result: Int
            repeat {
                result = Darwin.write(fileDescriptor, bytes.baseAddress, bytes.count)
            } while result < 0 && errno == EINTR
            return result
        }
        guard written == data.count else {
            throw ProviderFailure(message: "The provider command could not be sent. Please retry.")
        }
    }
}

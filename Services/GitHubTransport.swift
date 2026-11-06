import Foundation

/// The billing API and sign-in endpoints use separate, stateless sessions.
enum GitHubTransport {
    private final class NoRedirects: NSObject, URLSessionTaskDelegate, Sendable {
        func urlSession(_ session: URLSession, task: URLSessionTask,
                        willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? { nil }
    }

    static func session(requestTimeout: TimeInterval, resourceTimeout: TimeInterval) -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = requestTimeout
        configuration.timeoutIntervalForResource = resourceTimeout
        configuration.httpCookieStorage = nil
        configuration.urlCredentialStorage = nil
        configuration.urlCache = nil
        return URLSession(configuration: configuration, delegate: NoRedirects(), delegateQueue: nil)
    }

    static func body(_ bytes: URLSession.AsyncBytes, response: URLResponse, limit: Int, sizeError: String) async throws -> Data {
        guard response.expectedContentLength <= limit else { throw ProviderFailure(message: sizeError) }
        var data = Data()
        for try await byte in bytes {
            guard data.count < limit else { throw ProviderFailure(message: sizeError) }
            data.append(byte)
        }
        return data
    }
}

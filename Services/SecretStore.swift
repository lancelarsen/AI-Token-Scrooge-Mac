import Foundation
import Security

enum SecretStoreError: LocalizedError {
    case invalidID, unavailable
    var errorDescription: String? { "Scrooge could not access its saved credentials in Keychain. Please unlock your Keychain and try again." }
}
actor SecretStore {
    private final class CredentialQueue {
        let queue = DispatchQueue(label: "scrooge.keychain", qos: .utility)
        var pending = 0
    }

    private var queues: [String: CredentialQueue] = [:]
    private static let service = "com.lancelarsen.AITokenScrooge.credentials"

    // Keychain calls can wait for user interaction. Order operations on each
    // credential while allowing unrelated accounts and the actor to proceed.
    private func perform<Value: Sendable>(
        _ id: String, _ operation: @escaping @Sendable ([String: Any]) throws -> Value
    ) async throws -> Value {
        guard UUID(uuidString: id) != nil else { throw SecretStoreError.invalidID }
        let credential = queues[id] ?? CredentialQueue()
        queues[id] = credential
        credential.pending += 1
        defer {
            credential.pending -= 1
            if credential.pending == 0 { queues.removeValue(forKey: id) }
        }
        return try await withCheckedThrowingContinuation { continuation in
            credential.queue.async {
                let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: Self.service,
                    kSecAttrAccount as String: id
                ]
                continuation.resume(with: Result { try operation(query) })
            }
        }
    }

    func read(_ id: String) async throws -> Data? {
        try await perform(id) { query in
            var request = query
            request[kSecReturnData as String] = true; request[kSecMatchLimit as String] = kSecMatchLimitOne
            var value: CFTypeRef?
            let result = SecItemCopyMatching(request as CFDictionary, &value)
            if result == errSecItemNotFound { return nil }
            guard result == errSecSuccess, let data = value as? Data else { throw SecretStoreError.unavailable }
            return data
        }
    }

    func save(_ data: Data, id: String) async throws {
        try await perform(id) { query in
            let result = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
            if result == errSecItemNotFound {
                var request = query
                request[kSecValueData as String] = data
                request[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
                guard SecItemAdd(request as CFDictionary, nil) == errSecSuccess else { throw SecretStoreError.unavailable }
            } else if result != errSecSuccess { throw SecretStoreError.unavailable }
        }
    }

    func remove(_ id: String) async throws {
        try await perform(id) { query in
            let result = SecItemDelete(query as CFDictionary)
            guard result == errSecSuccess || result == errSecItemNotFound else { throw SecretStoreError.unavailable }
        }
    }
}

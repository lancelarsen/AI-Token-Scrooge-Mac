import Foundation
import Security

enum SecretStoreError: LocalizedError {
    case invalidID, unavailable
    var errorDescription: String? { "Scrooge could not access its saved credentials in Keychain. Unlock Keychain or use Sign In Again to authorize access." }
}
actor SecretStore {
    // The legacy login Keychain's interaction policy is process-wide. Keep every
    // credential operation on this shared queue so background maintenance cannot
    // disable interaction during an explicit sign-in save.
    private static let queue = DispatchQueue(label: "scrooge.keychain", qos: .utility)
    private static let service = "com.lancelarsen.AITokenScrooge.credentials"

    private func perform<Value: Sendable>(
        _ id: String, allowInteraction: Bool = false, _ operation: @escaping @Sendable ([String: Any]) throws -> Value
    ) async throws -> Value {
        guard UUID(uuidString: id) != nil else { throw SecretStoreError.invalidID }
        return try await withCheckedThrowingContinuation { continuation in
            Self.queue.async {
                let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: Self.service,
                    kSecAttrAccount as String: id
                ]
                continuation.resume(with: Result {
                    // Legacy login-Keychain policy is process-wide. Scope it to
                    // this serialized operation, including background writes.
                    var previous = DarwinBoolean(false)
                    guard SecKeychainGetUserInteractionAllowed(&previous) == errSecSuccess,
                          SecKeychainSetUserInteractionAllowed(allowInteraction) == errSecSuccess else {
                        throw SecretStoreError.unavailable
                    }
                    defer { _ = SecKeychainSetUserInteractionAllowed(previous.boolValue) }
                    return try operation(query)
                })
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

    func save(_ data: Data, id: String, allowInteraction: Bool = false) async throws {
        try await perform(id, allowInteraction: allowInteraction) { query in
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

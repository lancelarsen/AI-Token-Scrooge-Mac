import Foundation
import Security

enum SecretStoreError: LocalizedError {
    case invalidID, unavailable
    var errorDescription: String? { "Scrooge could not access its saved credentials in Keychain. Please unlock your Keychain and try again." }
}
actor SecretStore {
    private let service = "com.lancelarsen.AITokenScrooge.credentials"
    private func query(_ id: String) throws -> [String: Any] {
        guard UUID(uuidString: id) != nil else { throw SecretStoreError.invalidID }
        return [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: id]
    }
    func read(_ id: String) throws -> Data? {
        var request = try query(id)
        request[kSecReturnData as String] = true; request[kSecMatchLimit as String] = kSecMatchLimitOne
        var value: CFTypeRef?
        let result = SecItemCopyMatching(request as CFDictionary, &value)
        if result == errSecItemNotFound { return nil }
        guard result == errSecSuccess, let data = value as? Data else { throw SecretStoreError.unavailable }
        return data
    }
    func save(_ data: Data, id: String) throws {
        var request = try query(id)
        let result = SecItemUpdate(request as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if result == errSecItemNotFound {
            request[kSecValueData as String] = data
            request[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            guard SecItemAdd(request as CFDictionary, nil) == errSecSuccess else { throw SecretStoreError.unavailable }
        } else if result != errSecSuccess { throw SecretStoreError.unavailable }
    }
    func remove(_ id: String) throws {
        let result = SecItemDelete(try query(id) as CFDictionary)
        guard result == errSecSuccess || result == errSecItemNotFound else { throw SecretStoreError.unavailable }
    }
}

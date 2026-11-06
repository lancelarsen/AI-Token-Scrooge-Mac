import Foundation

/// Profiles are app-owned, private directories. Never follow redirected paths when
/// opening or removing one; keep failed cleanup queued for a later safe retry.
enum OwnedProfileDirectory {
    static func directory(provider: Provider, id: String, base: URL? = nil) throws -> URL {
        guard let uuid = UUID(uuidString: id), provider != .copilot else { throw SecretStoreError.invalidID }
        let support = base ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let root = support.appendingPathComponent("AI Token Scrooge", isDirectory: true)
        let parent = root.appendingPathComponent(provider == .codex ? "Profiles" : "ClaudeProfiles", isDirectory: true)
        let result = parent.appendingPathComponent(uuid.uuidString, isDirectory: true)
        try validateAncestors(support)
        for url in [root, parent, result] {
            if !FileManager.default.fileExists(atPath: url.path) {
                // A dangling symlink must not be mistaken for a missing directory.
                if (try? FileManager.default.attributesOfItem(atPath: url.path)) != nil { throw StoreError.operation }
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
            }
            try validate(url, directory: true)
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: url.path)
        }
        try validateContents(result, provider: provider)
        return result
    }
    static func remove(provider: Provider, id: String, base: URL? = nil) throws {
        let url = try directory(provider: provider, id: id, base: base)
        try FileManager.default.removeItem(at: url)
    }
    private static func validateContents(_ url: URL, provider: Provider) throws {
        var failed = false
        guard let walker = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil, options: [], errorHandler: { _, _ in failed = true; return false }) else { throw StoreError.operation }
        let executable = provider == .codex ? try? CodexConnection.executable() : nil
        for case let child as URL in walker {
            let relative = child.pathComponents.dropFirst(url.pathComponents.count)
            // Codex installs these helper aliases during app-server startup.
            if let executable, relative.count == 4, relative.prefix(2).elementsEqual(["tmp", "arg0"]),
               relative.dropFirst(2).first?.hasPrefix("codex-arg0") == true,
               ["applypatch", "apply_patch", "codex-execve-wrapper"].contains(child.lastPathComponent),
               let target = try? FileManager.default.destinationOfSymbolicLink(atPath: child.path),
               target == executable.path,
               (try FileManager.default.attributesOfItem(atPath: child.path)[.ownerAccountID] as? NSNumber)?.uint32Value == getuid() {
                walker.skipDescendants()
                continue
            }
            try validate(child, directory: false)
        }
        if failed { throw StoreError.operation }
    }
    private static func validateAncestors(_ url: URL) throws {
        var current = URL(fileURLWithPath: "/", isDirectory: true)
        for component in url.pathComponents.dropFirst() {
            current.appendPathComponent(component)
            let attributes = try FileManager.default.attributesOfItem(atPath: current.path)
            guard attributes[.type] as? FileAttributeType == .typeDirectory else { throw StoreError.operation }
        }
    }
    private static func validate(_ url: URL, directory: Bool) throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let type = attributes[.type] as? FileAttributeType
        guard type == .typeDirectory || (!directory && type == .typeRegular),
              (attributes[.ownerAccountID] as? NSNumber)?.uint32Value == getuid() else { throw StoreError.operation }
    }
}

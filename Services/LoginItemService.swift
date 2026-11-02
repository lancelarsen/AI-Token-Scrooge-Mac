import ServiceManagement

@MainActor enum LoginItemService {
    enum Status: Equatable { case enabled, disabled, approvalRequired, unavailable }
    static var status: Status {
        switch SMAppService.mainApp.status {
        case .enabled: .enabled
        case .notRegistered: .disabled
        case .requiresApproval: .approvalRequired
        case .notFound: .unavailable
        @unknown default: .unavailable
        }
    }
    static func apply(_ enabled: Bool) async throws {
        if enabled {
            if status != .enabled && status != .approvalRequired { try SMAppService.mainApp.register() }
        } else if status == .enabled || status == .approvalRequired { try await SMAppService.mainApp.unregister() }
    }
    static func openSettings() { SMAppService.openSystemSettingsLoginItems() }
}

import AppKit
import Combine
import Sparkle

/// Sparkle owns scheduling, signature validation, installation, and relaunch.
/// Its preferences are separate from provider data and never include credentials.
@MainActor final class AppUpdater: ObservableObject {
    static let shared = AppUpdater()
    @Published private(set) var canCheck = false
    @Published private(set) var lastChecked: Date?
    @Published var automaticChecks = true {
        didSet { if automaticChecks != controller.updater.automaticallyChecksForUpdates { controller.updater.automaticallyChecksForUpdates = automaticChecks } }
    }
    private let controller: SPUStandardUpdaterController
    static var displayVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "ScroogeDisplayVersion") as? String ?? "Development Build"
    }
    static var versionLabel: String {
        let version = displayVersion
        let isDevelopment = version.split(separator: ".").last.flatMap { Int($0) } == 0
        return "Version \(version)" + (isDevelopment ? " (Development Build)" : "")
    }
    private init() {
        controller = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil)
        automaticChecks = controller.updater.automaticallyChecksForUpdates
        controller.updater.publisher(for: \.canCheckForUpdates).assign(to: &$canCheck)
        controller.updater.publisher(for: \.lastUpdateCheckDate).assign(to: &$lastChecked)
        guard ProcessInfo.processInfo.environment["SCROOGE_TEST_MODE"] != "1" else { return }
        controller.startUpdater()
    }
    func checkNow() { controller.checkForUpdates(nil) }
}

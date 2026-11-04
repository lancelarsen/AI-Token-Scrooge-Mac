import SwiftUI
import AppKit
import UserNotifications
import Network

@main struct ScroogeApp: App {
    @NSApplicationDelegateAdaptor(ScroogeAppDelegate.self) private var delegate
    @State private var store = AppStore()
    private var statusSymbol: String {
        switch store.iconAlert?.severity {
        case .critical: "exclamationmark.octagon.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .info: "info.circle.fill"
        case nil: store.iconUnavailable ? "questionmark.circle" : "gauge.with.dots.needle.33percent"
        }
    }
    var body: some Scene {
        Window("AI Token Scrooge", id: "dashboard") {
            DashboardView().environment(store)
                .onAppear { delegate.store = store }
        }
        .defaultSize(width: 1460, height: 900)
        .commands { CommandGroup(after: .appInfo) { Button("Check for Updates…") { AppUpdater.shared.checkNow() } } }
        Settings { SettingsView().environment(store) }
            .defaultSize(width: 1000, height: 800)
        MenuBarExtra {
            MenuBarContent().environment(store)
        } label: {
            Image(systemName: statusSymbol)
                .accessibilityLabel(store.iconDescription)
                .help(store.iconDescription)
        }
    }
}

struct MenuBarContent: View {
    @Environment(AppStore.self) private var store
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Button("Open AI Token Scrooge") {
            openWindow(id: "dashboard")
            NSApp.activate(ignoringOtherApps: true)
        }
        Text(store.iconDescription)
        Button("Refresh All") { Task { await store.refresh() } }.disabled(store.isRefreshing)
        SettingsLink()
        Divider()
        Button("Quit AI Token Scrooge") { NSApp.terminate(nil) }.keyboardShortcut("q")
    }
}

@MainActor final class ScroogeAppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    weak var store: AppStore? { didSet { drainWhenReady() } }
    private var queuedResponses: [(id: String, action: String)] = []
    private var draining = false
    private var pathMonitor: NWPathMonitor?
    private var wakeObserver: NSObjectProtocol?
    private var networkWasAvailable: Bool?
    private func refreshAfterResume() {
        guard ProcessInfo.processInfo.environment["SCROOGE_TEST_MODE"] != "1",
              let store, !store.isLoading, !store.isDemo else { return }
        Task { await store.refresh() }
    }
    func applicationDidBecomeActive(_ notification: Notification) { refreshAfterResume() }
    func applicationWillTerminate(_ notification: Notification) {
        pathMonitor?.cancel()
        if let wakeObserver { NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver) }
    }
    private func drainWhenReady() {
        guard !draining, store != nil else { return }
        draining = true
        Task { [weak self] in
            guard let self else { return }
            defer { draining = false }
            while store?.isLoading == true { try? await Task.sleep(for: .milliseconds(100)) }
            guard let store else { return }
            let responses = queuedResponses; queuedResponses.removeAll()
            for response in responses {
                guard let alert = store.state.alerts.first(where: { $0.id == response.id }) else { continue }
                switch response.action {
                case "snooze": store.snooze(response.id, minutes: 60)
                case "dismiss": store.dismissAlert(response.id)
                default:
                    store.showAlertAccount(alert)
                }
            }
        }
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        let category = UNNotificationCategory(identifier: "quota-alert", actions: [
            UNNotificationAction(identifier: "show-info", title: "Show Info", options: .foreground),
            UNNotificationAction(identifier: "snooze", title: "Snooze 1 Hour"),
            UNNotificationAction(identifier: "dismiss", title: "Dismiss")
        ], intentIdentifiers: [])
        center.setNotificationCategories([category])
        guard ProcessInfo.processInfo.environment["SCROOGE_TEST_MODE"] != "1" else { return }
        _ = AppUpdater.shared
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refreshAfterResume() }
        }
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            let available = path.status == .satisfied
            Task { @MainActor [weak self] in
                guard let self else { return }
                let reconnected = networkWasAvailable == false && available
                networkWasAvailable = available
                if reconnected { refreshAfterResume() }
            }
        }
        pathMonitor = monitor
        monitor.start(queue: DispatchQueue(label: "com.lancelarsen.AITokenScrooge.network"))
    }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions { [.list] }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let id = response.notification.request.identifier
        let action = response.actionIdentifier
        await MainActor.run {
            queuedResponses.append((id, action))
            drainWhenReady()
        }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        !(store?.state.settings.closeToMenuBar ?? true)
    }
}

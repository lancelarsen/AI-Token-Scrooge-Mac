import Foundation
import Observation
import ServiceManagement
import AppKit

@MainActor @Observable final class AppStore {
    private(set) var state = PersistedState()
    private(set) var historyRevision: UInt64 = 0
    private(set) var history: [HistoryRun] = [] { didSet { historyRevision &+= 1 } }
    private(set) var historyLoading = false
    private(set) var historyError: String?
    private var historyRequest = UUID()
    private var historyCache: [String: HistoryRunCache] = [:]
    private(set) var isDemo = false
    private(set) var isLoading = true
    private(set) var isRefreshing = false
    private var pendingRefreshEpoch: UUID?
    var errorMessage: String?
    var selectedAccount: ProviderAccount?
    var highlightedAccountID: String?
    var accountRevealRequest = UUID()
    func showAlertAccount(_ alert: AlertEvent) {
        selectedAccount = nil
        showConnection = false
        showAlertHistory = false
        highlightedAccountID = state.accounts.contains { $0.id == alert.accountID } ? alert.accountID : nil
        accountRevealRequest = UUID()
        openDashboard?()
    }
    var reconnectAccountID: String?
    var showConnection = false
    private let github = GitHubClient()
    private let secrets = SecretStore()
    @ObservationIgnored private lazy var githubCredentials = GitHubCredentialManager(secrets: secrets, usage: github)
    private var schedule = RefreshSchedule()
    private var monitorTask: Task<Void, Never>?
    private var monitoringEpoch = UUID()
    var loginItemMessage: String?
    var loginItemNeedsApproval = false
    var activeAlert: AlertEvent?
    @ObservationIgnored var openDashboard: (() -> Void)?
    var iconAlert: AlertEvent? { IconAlertPolicy.evaluate(state: state, now: .now) }
    var monitorAvailability: MonitorAvailability { MonitorAvailability.evaluate(state) }
    var iconUnavailable: Bool { state.settings.alertOnIcon && monitorAvailability.needsAttention }
    var attentionCount: Int { iconAlert != nil || iconUnavailable ? 1 : 0 }
    var iconDescription: String {
        let status = monitorAvailability
        var summary = "AI Token Scrooge"
        if let account = state.accounts.first(where: { $0.id == status.accountID }),
           let window = state.snapshots[account.id]?.windows.first(where: { $0.id == status.windowID }) {
            summary = "Scrooge · \(account.provider.rawValue) / \(state.settings.privacy ? "Account" : account.nickname) / \(window.name): \(Format.percent(window.remainingPercent)) Left"
        }
        if let notice = status.notice { summary += " · " + notice }
        if let alert = iconAlert {
            summary = "Scrooge · " + alert.title + " · " + (state.settings.privacy ? "Account Details Hidden" : alert.detail)
        }
        return isDemo ? "DEMO · " + summary : summary
    }
    private var lastPruned: Date = .distantPast
    private var activeCredentialIDs: Set<String> = []
    private var lastCredentialCleanup: Date = .distantPast
    var showAlertHistory = false
    let database: LocalStore?
    private let notifications: any NotificationDelivering
    private var realState = PersistedState()
    // Serialize state edits through one queue so awaited writes cannot lose intervening changes.
    private var mutationTail: Task<Void, Never>?
    private var loadTask: Task<Void, Never>?
    private var localStateReady = false
    var accounts: [ProviderAccount] { AccountPolicy.ordered(state) }
    private var isTestLaunch: Bool { ProcessInfo.processInfo.environment["SCROOGE_TEST_MODE"] == "1" }
    init(database: LocalStore, notifications: any NotificationDelivering = NotificationService.shared) {
        self.database = database
        self.notifications = notifications
    }
    func waitForPendingMutations() async { await mutationTail?.value }
    init() {
        notifications = NotificationService.shared
        let args = ProcessInfo.processInfo.arguments
        let override = args.firstIndex(of: "--data-dir").flatMap { args.indices.contains($0 + 1) ? args[$0 + 1] : nil }
        let defaultBase = ProcessInfo.processInfo.environment["SCROOGE_TEST_MODE"] == "1"
            ? FileManager.default.temporaryDirectory.appendingPathComponent("ScroogeTests-" + UUID().uuidString)
            : FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("AI Token Scrooge")
        let base = override.map { URL(fileURLWithPath: $0) } ?? defaultBase
        do { database = try LocalStore(url: base.appendingPathComponent("scrooge.db")) }
        catch { database = nil; errorMessage = error.localizedDescription }
    }
    func load() async {
        if let loadTask { await loadTask.value; return }
        guard isLoading else { return }
        let previous = mutationTail
        let loading = Task { [weak self] in
            await previous?.value
            await self?.performLoad()
        }
        loadTask = loading; mutationTail = loading
        await loading.value
    }
    private func performLoad() async {
        defer { isLoading = false; startMonitoring() }
        do {
            guard let database else { throw StoreError.operation }
            state = try await database.load(); localStateReady = true
            for id in state.snapshots.keys { state.snapshots[id]?.health = .stale; state.snapshots[id]?.message = "Saved Values — Refreshing" }
            if ProcessInfo.processInfo.arguments.contains("--demo") { enterDemo() }
            else { await reconcileLoginItem(); await reloadHistory() }
        } catch { errorMessage = error.localizedDescription }
    }
    func edit(_ mutation: @escaping @MainActor (inout PersistedState) -> Void) {
        let previous = mutationTail
        mutationTail = Task { [weak self] in
            await previous?.value
            guard let self else { return }
            var candidate = state; mutation(&candidate)
            do {
                guard candidate.settings.thresholds.isValid else { throw PreferenceError.invalidThresholds }
                if !isDemo {
                    guard localStateReady, let database else { throw StoreError.operation }
                    try await database.save(candidate)
                }
                if candidate.settings.historyRetentionDays != state.settings.historyRetentionDays { lastPruned = .distantPast }
                let zoneChanged = candidate.settings.timeZoneID != state.settings.timeZoneID
                state = candidate
                if zoneChanged && !isDemo { historyCache.removeAll(); await reloadHistory() }
            } catch { errorMessage = error.localizedDescription }
        }
    }
    func enterDemo() {
        let previous = mutationTail
        mutationTail = Task { [weak self] in
            await previous?.value
            guard let self, !isDemo else { return }
            monitoringEpoch = UUID(); activeAlert = nil
            realState = state
            let arguments = ProcessInfo.processInfo.arguments
            let scenario = arguments.firstIndex(of: "--scenario").flatMap { index in
                arguments.indices.contains(index + 1) ? DemoData.Scenario(rawValue: arguments[index + 1]) : nil
            } ?? .standard
            let demo = DemoData.make(now: .now, scenario: scenario)
            historyRequest = UUID(); historyLoading = false; historyError = nil
            state = demo.0; history = demo.1; isDemo = true
        }
    }
    func exitDemo() {
        let previous = mutationTail
        mutationTail = Task { [weak self] in
            await previous?.value
            guard let self, isDemo else { return }
            monitoringEpoch = UUID(); activeAlert = nil
            state = realState; history = []; isDemo = false; schedule.reset()
            await reloadHistory()
        }
    }
    private func startMonitoring() {
        guard monitorTask == nil, !isTestLaunch, localStateReady else { return }
        monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await mutationTail?.value
                await refresh(force: false)
                await pruneHistoryIfNeeded()
                await cleanupRetiredCredentials()
                updateBadge()
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
            }
        }
    }
    private func cleanupRetiredCredentials() async {
        guard !isDemo, !isRefreshing, Date.now.timeIntervalSince(lastCredentialCleanup) >= 300 else { return }
        lastCredentialCleanup = .now
        let retired = state.retiredAccounts
        for account in retired {
            guard !activeCredentialIDs.contains(account.credentialID), !state.accounts.contains(where: { $0.credentialID == account.credentialID }) else { continue }
            do {
                switch account.provider {
                case .copilot: try await githubCredentials.remove(account.credentialID)
                case .codex:
                    let connection = try await CodexConnection.start(credentialID: account.credentialID)
                    do { _ = try await connection.call("account/logout") }
                    catch { await connection.close(); throw error }
                    await connection.close()
                case .claude: try await ClaudeClient().disconnect(account.credentialID)
                }
                if account.provider != .copilot {
                    try OwnedProfileDirectory.remove(provider: account.provider, id: account.credentialID)
                }
                edit { state in state.retiredAccounts.removeAll { $0.credentialID == account.credentialID } }
                await mutationTail?.value
            } catch { /* Retain the cleanup record and retry; never retire the active credential. */ }
        }
        for id in state.retiredCredentialIDs where !state.accounts.contains(where: { $0.credentialID == id }) {
            do {
                try await githubCredentials.remove(id)
                edit { $0.retiredCredentialIDs.removeAll { $0 == id } }
                await mutationTail?.value
            } catch { }
        }
    }
    private func updateBadge() {
        let count = attentionCount
        NSApp.dockTile.badgeLabel = count == 0 ? nil : "!"
    }
    private func pruneHistoryIfNeeded() async {
        guard !isDemo, Date.now.timeIntervalSince(lastPruned) >= 3600 else { return }
        let previous = mutationTail
        let pruning = Task { [weak self] in
            await previous?.value
            guard let self, !isDemo, let database else { return }
            do {
                var candidate = state
                let cutoff = Date.now.addingTimeInterval(-Double(candidate.settings.historyRetentionDays) * 86400)
                candidate.alerts.removeAll { $0.createdAt < cutoff }
                try await database.prune(now: .now, days: candidate.settings.historyRetentionDays, state: candidate)
                state = candidate; lastPruned = .now; historyCache.removeAll()
            } catch { errorMessage = error.localizedDescription }
        }
        mutationTail = pruning; await pruning.value
    }
    func dismissAlert(_ id: String) {
        saveAlertAction(id, cue: "dismiss") { $0.dismissed = true }
    }
    private func saveAlertAction(_ id: String, cue: String, mutation: @escaping @MainActor (inout AlertEvent) -> Void) {
        let bannerID = activeAlert?.id
        let previous = mutationTail
        mutationTail = Task { [weak self] in
            await previous?.value
            guard let self, let index = state.alerts.firstIndex(where: { $0.id == id }) else { return }
            var candidate = state
            mutation(&candidate.alerts[index])
            if cue == "snooze", let until = candidate.alerts[index].snoozedUntil {
                candidate.snoozedAccounts[candidate.alerts[index].accountID] = until
            }
            do {
                if !isDemo {
                    guard localStateReady, let database else { throw StoreError.operation }
                    try await database.save(candidate)
                }
                state = candidate
                if activeAlert?.id == bannerID,
                   (activeAlert?.id == id || (cue == "snooze" && activeAlert?.accountID == candidate.alerts[index].accountID)) {
                    activeAlert = nil
                }
                await notifications.cancel(id)
                SoundPlayer.shared.play(settings: state.settings, cue: cue)
            } catch { errorMessage = error.localizedDescription }
        }
    }
    private func deliver(_ alert: AlertEvent, account: ProviderAccount, epoch: UUID) async {
        func eligible() -> Bool {
            guard !isDemo, monitoringEpoch == epoch,
                  state.accounts.contains(where: { $0.id == account.id && $0.generation == account.generation }),
                  let current = state.alerts.first(where: { $0.id == alert.id }), !current.delivered else { return false }
            return AlertDeliveryPolicy.canDeliver(current, state: state, now: .now)
        }
        guard eligible() else { return }
        activeAlert = alert
        SoundPlayer.shared.play(settings: state.settings, cue: "alert")
        do {
            try await notifications.authorize()
            await mutationTail?.value
            guard eligible() else {
                if activeAlert?.id == alert.id { activeAlert = nil }
                return
            }
            try await notifications.enqueue(id: alert.id, title: alert.title,
                detail: state.settings.privacy ? "Account details hidden. Open AI Token Scrooge for details." : alert.detail)
            await mutationTail?.value
            guard eligible() else {
                await notifications.cancel(alert.id)
                if activeAlert?.id == alert.id { activeAlert = nil }
                return
            }
            edit { state in
                if let index = state.alerts.firstIndex(where: { $0.id == alert.id }) { state.alerts[index].delivered = true }
            }
        } catch { if eligible() { errorMessage = error.localizedDescription } }
    }
    func setHistory(_ enabled: Bool) { edit { $0.settings.historyEnabled = enabled } }
    func toggleAccountHistory(_ id: String) {
        edit { state in
            if state.settings.hiddenHistoryAccounts.contains(id) { state.settings.hiddenHistoryAccounts.remove(id) }
            else { state.settings.hiddenHistoryAccounts.insert(id) }
        }
    }
    func toggleCapacity(account: String, window: String) {
        edit { state in
            let key = QuotaAlertSection(accountID: account, windowID: window)
            if state.settings.disabledCapacityAlerts.contains(key) { state.settings.disabledCapacityAlerts.removeAll { $0 == key } }
            else { state.settings.disabledCapacityAlerts.append(key) }
        }
    }
    func setThresholds(account: String, window: String, thresholds: AlertThresholds) {
        edit { state in
            var rule = state.settings.rule(accountID: account, windowID: window)
            rule.windowID = window; rule.thresholds = thresholds
            state.settings.rules.removeAll { $0.accountID == account && $0.windowID == window }
            state.settings.rules.append(rule)
        }
    }
    func reorder(_ dragged: String, before target: String) {
        edit { state in
            guard state.settings.accountSort == .custom, dragged != target,
                  state.accounts.contains(where: { $0.id == dragged }) else { return }
            var order = AccountPolicy.ordered(state).map(\.id).filter { $0 != dragged }
            guard let index = order.firstIndex(of: target) else { return }
            order.insert(dragged, at: index); state.settings.accountOrder = order; state.settings.accountSort = .custom
        }
    }
    func reloadHistory() async {
        guard !isDemo, let database else { return }
        let request = UUID(); historyRequest = request; historyLoading = true; historyError = nil
        defer { if historyRequest == request { historyLoading = false } }
        let epoch = monitoringEpoch
        let accounts = state.accounts
        let zone = state.settings.zone
        let since = HorizonViewport(now: .now, furthestFuture: nil, zone: zone, width: 700).date(at: 0)
        do {
            var caches = historyCache
            var result: [HistoryRun] = []
            for account in accounts {
                var cache = caches[account.id] ?? HistoryRunCache()
                if !cache.covers(since: since) { cache = HistoryRunCache() }
                let delta = try await database.historyChanges(accountID: account.id, since: since, afterRevision: cache.revision)
                cache.merge(delta.runs, revision: delta.revision, since: since)
                caches[account.id] = cache; result += cache.runs
            }
            guard historyRequest == request, !isDemo, monitoringEpoch == epoch, state.accounts == accounts, state.settings.zone == zone else { return }
            historyCache = caches.filter { id, _ in accounts.contains { $0.id == id } }
            history = result
        } catch {
            guard historyRequest == request, !isDemo, monitoringEpoch == epoch, state.accounts == accounts, state.settings.zone == zone else { return }
            historyError = "History Could Not Be Loaded. Previously Loaded Observations Are Retained."
            errorMessage = error.localizedDescription
        }
    }
    func refreshLoginItemStatus() {
        guard !isDemo, !isTestLaunch else { loginItemMessage = nil; loginItemNeedsApproval = false; return }
        loginItemNeedsApproval = LoginItemService.status == .approvalRequired
        switch LoginItemService.status {
        case .enabled: loginItemMessage = "Enabled in macOS Login Items."
        case .disabled: loginItemMessage = state.settings.launchAtSignIn ? "Not currently registered with macOS." : nil
        case .approvalRequired: loginItemMessage = "Allow AI Token Scrooge in System Settings → General → Login Items."
        case .unavailable: loginItemMessage = "macOS could not locate this app as a login item. Move it to Applications and try again."
        }
    }
    private func reconcileLoginItem() async {
        guard !isDemo, !isTestLaunch else { return }
        do { try await LoginItemService.apply(state.settings.launchAtSignIn) }
        catch {
            var candidate = state; candidate.settings.launchAtSignIn = false
            do {
                guard let database else { throw StoreError.operation }
                try await database.save(candidate); state = candidate
            } catch { errorMessage = error.localizedDescription }
            loginItemMessage = "Launch at Sign-In could not be enabled. You can try again in Settings."
            return
        }
        refreshLoginItemStatus()
    }
    func setLaunchAtSignIn(_ enabled: Bool) {
        guard !isDemo, !isTestLaunch else { edit { $0.settings.launchAtSignIn = enabled }; return }
        let previous = mutationTail
        mutationTail = Task { [weak self] in
            await previous?.value
            guard let self else { return }
            let old = state.settings.launchAtSignIn
            do {
                try await LoginItemService.apply(enabled)
                var candidate = state; candidate.settings.launchAtSignIn = enabled
                guard let database else { throw StoreError.operation }
                try await database.save(candidate); state = candidate
            } catch {
                try? await LoginItemService.apply(old)
                errorMessage = error.localizedDescription
            }
            refreshLoginItemStatus()
        }
    }
    func sendTestNotification() async {
        let epoch = monitoringEpoch
        let alert = AlertEvent(id: "test/" + UUID().uuidString,
            accountID: state.accounts.first?.id ?? "test", windowID: nil,
            title: "Scrooge Notification Test",
            detail: "This is a test. Your account usage has not changed.", createdAt: .now)
        edit { $0.alerts.append(alert) }
        await mutationTail?.value
        guard monitoringEpoch == epoch, state.alerts.contains(where: { $0.id == alert.id }) else { return }
        activeAlert = alert
        openDashboard?()
        SoundPlayer.shared.play(settings: state.settings, cue: "alert", preview: true)
        do {
            try await notifications.authorize()
            await mutationTail?.value
            guard monitoringEpoch == epoch, let current = state.alerts.first(where: { $0.id == alert.id }),
                  !current.dismissed, current.snoozedUntil == nil else { return }
            try await notifications.enqueue(id: alert.id, title: alert.title, detail: alert.detail)
            await mutationTail?.value
            guard monitoringEpoch == epoch, let current = state.alerts.first(where: { $0.id == alert.id }),
                  !current.dismissed, current.snoozedUntil == nil else {
                await notifications.cancel(alert.id)
                return
            }
            edit { state in
                if let index = state.alerts.firstIndex(where: { $0.id == alert.id }) { state.alerts[index].delivered = true }
            }
            await mutationTail?.value
        } catch {
            if monitoringEpoch == epoch {
                errorMessage = "macOS did not accept the test notification. The test is recorded in Alert History. " + error.localizedDescription
            }
        }
    }
    func snooze(_ id: String, minutes: Int) {
        guard minutes > 0 && minutes <= 120 else { return }
        saveAlertAction(id, cue: "snooze") { alert in
            alert.snoozedUntil = .now.addingTimeInterval(Double(minutes) * 60)
        }
    }
    func removeAccount(_ id: String) async {
        let previous = mutationTail
        let removal = Task { [weak self] in
            await previous?.value
            guard let self, let account = state.accounts.first(where: { $0.id == id }) else { return }
            var candidate = state
            candidate.accounts.removeAll { $0.id == id }
            candidate.snapshots.removeValue(forKey: id)
            candidate.alerts.removeAll { $0.accountID == id }
            candidate.snoozedAccounts.removeValue(forKey: id)
            candidate.settings.accountOrder.removeAll { $0 == id }
            candidate.settings.hiddenHistoryAccounts.remove(id)
            candidate.settings.rules.removeAll { $0.accountID == id }
            candidate.settings.disabledCapacityAlerts.removeAll { $0.accountID == id }
            candidate.retiredAccounts.append(account)
            do {
                if !isDemo {
                    guard let database else { throw StoreError.operation }
                    try await database.removeAccount(id, state: candidate)
                }
                state = candidate; history.removeAll { $0.snapshot.accountID == id }
                lastCredentialCleanup = .distantPast
            } catch { errorMessage = error.localizedDescription }
        }
        mutationTail = removal
        await removal.value
    }
    /// Persist cleanup intent before a provider can write credentials. Reuse the durable
    /// retirement queue so interrupted sign-ins are recovered on the next launch.
    func stageCredential(provider: Provider, id: String) async throws {
        guard UUID(uuidString: id) != nil else { throw SecretStoreError.invalidID }
        activeCredentialIDs.insert(id)
        let previous = mutationTail
        let commit = Task { @MainActor [weak self] in
            await previous?.value
            guard let self, !isDemo, localStateReady, let database else { throw StoreError.operation }
            guard !state.accounts.contains(where: { $0.credentialID == id }) else { throw StoreError.operation }
            var candidate = state
            if !candidate.retiredAccounts.contains(where: { $0.credentialID == id }) {
                candidate.retiredAccounts.append(ProviderAccount(provider: provider, nickname: "Pending sign-in", subject: "", scope: "", credentialID: id))
            }
            try await database.save(candidate)
            state = candidate
        }
        mutationTail = Task { _ = try? await commit.value }
        do { try await commit.value }
        catch { activeCredentialIDs.remove(id); throw error }
    }
    func endCredentialAttempt(_ id: String) {
        activeCredentialIDs.remove(id)
        lastCredentialCleanup = .distantPast
    }
    /// Connection commits share the mutation queue with settings, refreshes and removal.
    func acceptConnection(_ account: ProviderAccount, snapshot: QuotaSnapshot, replacing original: ProviderAccount?) async throws {
        let previous = mutationTail
        let commit = Task { @MainActor [weak self] in
            await previous?.value
            try Task.checkCancellation()
            guard let self, !isDemo, localStateReady, let database else { throw StoreError.operation }
            if let original {
                guard state.accounts.contains(where: { $0.id == original.id && $0.generation == original.generation }) else {
                    throw ProviderFailure(message: "This connection changed while signing in. Please reconnect again.")
                }
            }
            guard snapshot.belongs(to: account) else { throw AccountError.differentIdentity }
            guard !state.accounts.contains(where: { $0.id != account.id && $0.provider == account.provider && $0.subject == account.subject && $0.scopeEquals(account.scope) }) else {
                throw ProviderFailure(message: "This account is already connected.")
            }
            var candidate = state
            if let index = candidate.accounts.firstIndex(where: { $0.id == account.id }) { candidate.accounts[index] = account }
            else { candidate.accounts.append(account); candidate.settings.accountOrder.append(account.id) }
            candidate.snapshots[account.id] = snapshot
            candidate.retiredAccounts.removeAll { $0.credentialID == account.credentialID }
            if let original { candidate.retiredAccounts.append(original) }
            try await database.accept(snapshot, account: account, state: candidate)
            state = candidate; reconnectAccountID = nil; lastCredentialCleanup = .distantPast
        }
        mutationTail = Task { _ = try? await commit.value }
        try await commit.value
        await reloadHistory()
    }
    func connectGitHub(nickname: String, token: String, allowance: Decimal?, unit: UsageUnit, organization: String, appTokens: GitHubAppTokens? = nil) async throws {
        let original = state.accounts.first { $0.id == reconnectAccountID }
        let identity = try await github.identify(token: token)
        var account = ProviderAccount(provider: .copilot, nickname: nickname, subject: identity.subject,
            scope: organization.isEmpty ? "personal" : "organization:" + organization.lowercased(), allowance: allowance, unit: unit, login: identity.login)
        if let original { account.id = original.id; account = try AccountPolicy.reconnect(original: original, replacement: account) }
        var snapshot: QuotaSnapshot
        do { snapshot = try await github.read(account: account, token: token) }
        catch let error as ProviderFailure {
            snapshot = QuotaSnapshot(accountID: account.id, subject: account.subject, scope: account.scope, observedAt: .now, windows: [], health: error.health, message: error.message)
        }
        try Task.checkCancellation()
        try await stageCredential(provider: .copilot, id: account.credentialID)
        defer { endCredentialAttempt(account.credentialID) }
        if let appTokens { try await githubCredentials.saveApp(id: account.credentialID, subject: account.subject, tokens: appTokens) }
        else { try await secrets.save(Data(token.utf8), id: account.credentialID) }
        do {
            try Task.checkCancellation()
            try await acceptConnection(account, snapshot: snapshot, replacing: original)
        }
        catch { try? await secrets.remove(account.credentialID); throw error }
    }

    func refresh(force: Bool = true) async {
        guard !isDemo else { return }
        if isRefreshing {
            if force { pendingRefreshEpoch = monitoringEpoch }
            return
        }
        let epoch = monitoringEpoch
        isRefreshing = true
        defer {
            isRefreshing = false
            let requestedEpoch = pendingRefreshEpoch
            pendingRefreshEpoch = nil
            if requestedEpoch == monitoringEpoch {
                Task { [weak self] in
                    guard let self, !isDemo, monitoringEpoch == requestedEpoch else { return }
                    await refresh()
                }
            }
        }
        for account in state.accounts where account.enabled {
            guard !isDemo, monitoringEpoch == epoch else { break }
            if !schedule.shouldRefresh(account.id, now: .now, force: force) { continue }
            var freshAlerts: [AlertEvent] = []
            var snapshot: QuotaSnapshot
            var requestSucceeded = false
            var retryAt: Date?
            do {
                switch account.provider {
                case .codex:
                    let connection = try await CodexConnection.start(credentialID: account.credentialID)
                    do { snapshot = try await connection.snapshot(account: account) }
                    catch { await connection.close(); throw error }
                    await connection.close()
                case .copilot:
                    let token = try await githubCredentials.accessToken(for: account)
                    snapshot = try await github.read(account: account, token: token)
                case .claude:
                    snapshot = try await ClaudeClient().refresh(account)
                }
                guard snapshot.belongs(to: account) else { throw AccountError.differentIdentity }
                requestSucceeded = true
            } catch {
                let failure = error as? ProviderFailure
                retryAt = failure?.retryAt
                snapshot = state.snapshots[account.id] ?? QuotaSnapshot(accountID: account.id, subject: account.subject, scope: account.scope, observedAt: .now, windows: [])
                snapshot.health = failure?.health ?? (error is AccountError ? .authenticationRequired : .offline)
                snapshot.message = failure?.message ?? "Refresh failed. Last known values are retained."
            }
            let result = snapshot
            let succeeded = requestSucceeded
            let retryDeadline = retryAt
            let previous = mutationTail
            let acceptance = Task { [weak self] in
                await previous?.value
                guard let self, !isDemo, monitoringEpoch == epoch, state.accounts.contains(where: { $0.id == account.id && $0.generation == account.generation && $0.enabled }) else { return }
                // Only the current connection may change scheduling. Preserve provider
                // throttles even when the subsequent local persistence fails.
                if succeeded { schedule.succeeded(result, account: account, now: .now) }
                else { schedule.failed(account.id, now: .now, retryAt: retryDeadline) }
                var candidate = state
                let alerts = AlertEvaluator.evaluate(account: account, previous: candidate.snapshots[account.id], current: result, settings: candidate.settings, now: .now)
                candidate.snapshots[account.id] = result
                for alert in alerts where !candidate.alerts.contains(where: { $0.id == alert.id }) { candidate.alerts.append(alert); freshAlerts.append(alert) }
                do {
                    guard let database else { throw StoreError.operation }
                    if result.health == .healthy { try await database.accept(result, account: account, state: candidate) }
                    else { try await database.save(candidate) }
                    state = candidate
                } catch { errorMessage = error.localizedDescription }
            }
            mutationTail = acceptance
            await acceptance.value
            for alert in freshAlerts where state.alerts.contains(where: { $0.id == alert.id }) { await deliver(alert, account: account, epoch: epoch) }
        }
        await reloadHistory()
    }

}
enum PreferenceError: LocalizedError { case invalidThresholds
    var errorDescription: String? { "Alert levels must satisfy Critical < Warning ≤ Info, between 0 and 100." }
}

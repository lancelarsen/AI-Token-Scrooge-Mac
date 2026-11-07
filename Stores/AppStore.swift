import Foundation
import Observation
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
    @ObservationIgnored private let referenceDemoDate = DemoData.referenceDate(arguments: ProcessInfo.processInfo.arguments)
    var presentationDate: Date { isDemo ? referenceDemoDate ?? .now : .now }
    private(set) var isLoading = true
    private var refreshingCredentials: Set<String> = []
    @ObservationIgnored private var pendingRefreshes: [String: (account: ProviderAccount, epoch: UUID)] = [:]
    var isRefreshing: Bool { !isDemo && !refreshingCredentials.isEmpty }
    var canRequestRefresh: Bool {
        !isDemo && state.accounts.contains {
            $0.enabled && !refreshingCredentials.contains($0.credentialID) && schedule.shouldRefresh($0.id, now: .now, force: true)
        }
    }
    var errorMessage: String?
    var highlightedAccountID: String?
    var accountRevealRequest = UUID()
    func showAlertAccount(_ alert: AlertEvent?) {
        highlightedAccountID = alert.flatMap { target in
            state.accounts.first { $0.id == target.accountID }?.id
        }
        accountRevealRequest = UUID()
        dashboardOpenRequest = UUID()
    }
    private let github = GitHubClient()
    private let secrets = SecretStore()
    @ObservationIgnored private lazy var githubCredentials = GitHubCredentialManager(secrets: secrets, usage: github)
    private var schedule = RefreshSchedule()
    private var monitorTask: Task<Void, Never>?
    @ObservationIgnored private var maintenanceTask: Task<Void, Never>?
    private var monitoringEpoch = UUID()
    var loginItemMessage: String?
    var loginItemNeedsApproval = false
    var activeAlert: AlertEvent?
    private(set) var dashboardOpenRequest = UUID()
    var iconAlert: AlertEvent? { IconAlertPolicy.evaluate(state: state, now: presentationDate) }
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
    let database: LocalStore?
    private let notifications: any NotificationDelivering
    private let refreshAccount: (@Sendable (ProviderAccount) async throws -> QuotaSnapshot)?
    private var realState = PersistedState()
    // Serialize state edits through one queue so awaited writes cannot lose intervening changes.
    @ObservationIgnored private var mutationTail: Task<Void, Never>?
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    private var localStateReady = false
    var accounts: [ProviderAccount] { AccountPolicy.ordered(state) }
    private var isTestLaunch: Bool { ProcessInfo.processInfo.environment["SCROOGE_TEST_MODE"] == "1" }
    init(database: LocalStore, notifications: any NotificationDelivering = NotificationService.shared,
         refreshAccount: (@Sendable (ProviderAccount) async throws -> QuotaSnapshot)? = nil) {
        self.database = database
        self.notifications = notifications
        self.refreshAccount = refreshAccount
    }
    func waitForPendingMutations() async { await mutationTail?.value }

    @discardableResult
    private func enqueueMutation(_ operation: @escaping @MainActor () async -> Void) -> Task<Void, Never> {
        let previous = mutationTail
        let task = Task {
            await previous?.value
            await operation()
        }
        mutationTail = task
        return task
    }

    /// A dismissed sign-in can cancel a queued write until persistence starts.
    private func performCredentialMutation(_ operation: @escaping @MainActor () async throws -> Void) async throws {
        let previous = mutationTail
        let task = Task {
            await previous?.value
            try Task.checkCancellation()
            try await operation()
        }
        mutationTail = Task { _ = try? await task.value }
        try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }

    init() {
        notifications = NotificationService.shared
        refreshAccount = nil
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
        let loading = enqueueMutation { [self] in await performLoad() }
        loadTask = loading
        await loading.value
    }
    private func performLoad() async {
        defer { isLoading = false; startMonitoring() }
        do {
            guard let database else { throw StoreError.operation }
            state = try await database.load(); localStateReady = true
            for id in state.snapshots.keys { state.snapshots[id]?.health = .stale; state.snapshots[id]?.message = "Saved Values — Refreshing" }
            if ProcessInfo.processInfo.arguments.contains("--demo") { loadDemoState() }
            else { await reconcileLoginItem(); await reloadHistory() }
        } catch { errorMessage = error.localizedDescription }
    }
    func edit(_ mutation: @escaping @MainActor (inout PersistedState) -> Void) {
        enqueueMutation { [self] in
            var candidate = state; mutation(&candidate)
            do {
                try candidate.validate()
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
        enqueueMutation { [self] in loadDemoState() }
    }

    private func loadDemoState() {
        guard !isDemo else { return }
        monitoringEpoch = UUID(); activeAlert = nil
        realState = state
        let arguments = ProcessInfo.processInfo.arguments
        let scenario = arguments.firstIndex(of: "--scenario").flatMap { index in
            arguments.indices.contains(index + 1) ? DemoData.Scenario(rawValue: arguments[index + 1]) : nil
        } ?? .standard
        let demo = DemoData.make(now: referenceDemoDate ?? .now, scenario: scenario)
        historyRequest = UUID(); historyLoading = false; historyError = nil
        state = demo.0; history = demo.1; isDemo = true
    }
    func exitDemo() {
        enqueueMutation { [self] in
            guard isDemo else { return }
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
                startRefreshes(force: false)
                if maintenanceTask == nil {
                    maintenanceTask = Task {
                        await pruneHistoryIfNeeded()
                        await cleanupRetiredCredentials()
                        maintenanceTask = nil
                    }
                }
                updateBadge()
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
            }
        }
    }
    private func cleanupRetiredCredentials() async {
        guard !isDemo, Date.now.timeIntervalSince(lastCredentialCleanup) >= 300 else { return }
        lastCredentialCleanup = .now
        let epoch = monitoringEpoch
        func canRetire(_ id: String) -> Bool {
            monitoringEpoch == epoch && !isDemo && !refreshingCredentials.contains(id) &&
                !activeCredentialIDs.contains(id) && !state.accounts.contains { $0.credentialID == id }
        }
        for account in state.retiredAccounts {
            let id = account.credentialID
            guard canRetire(id), state.retiredAccounts.contains(where: { $0.credentialID == id }) else { continue }
            do {
                switch account.provider {
                case .devin: try await secrets.remove(account.credentialID)
                case .copilot: try await githubCredentials.remove(account.credentialID)
                case .codex:
                    let connection = try await CodexConnection.start(credentialID: account.credentialID)
                    do { _ = try await connection.call("account/logout") }
                    catch { await connection.close(); throw error }
                    await connection.close()
                case .claude: try await ClaudeClient().disconnect(account.credentialID)
                }
                guard canRetire(id) else { continue }
                if account.provider == .codex || account.provider == .claude {
                    try OwnedProfileDirectory.remove(provider: account.provider, id: id)
                }
                edit { candidate in
                    guard self.monitoringEpoch == epoch else { return }
                    candidate.retiredAccounts.removeAll { $0.credentialID == id }
                }
                await mutationTail?.value
            } catch { /* Retain the cleanup record and retry; never retire the active credential. */ }
        }
        for id in state.retiredCredentialIDs where canRetire(id) && state.retiredCredentialIDs.contains(id) {
            do {
                try await githubCredentials.remove(id)
                edit { candidate in
                    guard self.monitoringEpoch == epoch else { return }
                    candidate.retiredCredentialIDs.removeAll { $0 == id }
                }
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
        await enqueueMutation { [self] in
            guard !isDemo, let database else { return }
            do {
                var candidate = state
                let cutoff = Date.now.addingTimeInterval(-Double(candidate.settings.historyRetentionDays) * 86400)
                candidate.alerts.removeAll { $0.createdAt < cutoff }
                try await database.prune(now: .now, days: candidate.settings.historyRetentionDays, state: candidate)
                state = candidate; lastPruned = .now; historyCache.removeAll()
                await reloadHistory()
            } catch { errorMessage = error.localizedDescription }
        }.value
    }
    func dismissAlert(_ id: String) {
        saveAlertAction(id, cue: "dismiss") { $0.dismissed = true }
    }
    private func saveAlertAction(_ id: String, cue: String, mutation: @escaping @MainActor (inout AlertEvent) -> Void) {
        let bannerID = activeAlert?.id
        enqueueMutation { [self] in
            guard let index = state.alerts.firstIndex(where: { $0.id == id }) else { return }
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
            guard currentAccount(account, epoch: epoch) != nil,
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
    func setCapacityAlerts(_ enabled: Bool, account: String, window: String) {
        edit { state in
            let key = QuotaAlertSection(accountID: account, windowID: window)
            if enabled {
                state.settings.disabledCapacityAlerts.removeAll { $0 == key }
            } else if !state.settings.disabledCapacityAlerts.contains(key) {
                state.settings.disabledCapacityAlerts.append(key)
            }
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
    func moveAccount(_ id: String, to slot: Int, expectedOrder: [String]) async {
        edit { state in
            guard state.settings.accountSort == .custom,
                  AccountPolicy.ordered(state).map(\.id) == expectedOrder,
                  expectedOrder.contains(id), expectedOrder.indices.contains(slot) else { return }
            var order = expectedOrder.filter { $0 != id }
            order.insert(id, at: slot)
            state.settings.accountOrder = order
        }
        await mutationTail?.value
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
                guard historyRequest == request else { return }
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
        enqueueMutation { [self] in
            var candidate = state
            candidate.settings.launchAtSignIn = enabled
            if isDemo { state = candidate; return }
            guard localStateReady, let database else {
                errorMessage = StoreError.operation.localizedDescription
                return
            }
            do {
                if !isTestLaunch { try await LoginItemService.apply(enabled) }
                try await database.save(candidate)
                state = candidate
            } catch {
                if !isTestLaunch { try? await LoginItemService.apply(state.settings.launchAtSignIn) }
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
        dashboardOpenRequest = UUID()
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
        await enqueueMutation { [self] in
            guard let account = state.accounts.first(where: { $0.id == id }) else { return }
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
        }.value
    }
    /// Persist cleanup intent before a provider can write credentials. Reuse the durable
    /// retirement queue so interrupted sign-ins are recovered on the next launch.
    func stageCredential(provider: Provider, id: String) async throws {
        guard UUID(uuidString: id) != nil else { throw SecretStoreError.invalidID }
        activeCredentialIDs.insert(id)
        do {
            try await performCredentialMutation { [self] in
                guard !isDemo, localStateReady, let database,
                      !state.accounts.contains(where: { $0.credentialID == id }) else { throw StoreError.operation }
                var candidate = state
                if !candidate.retiredAccounts.contains(where: { $0.credentialID == id }) {
                    candidate.retiredAccounts.append(ProviderAccount(provider: provider, nickname: "Pending sign-in", subject: "", scope: "", credentialID: id))
                }
                try await database.save(candidate)
                state = candidate
            }
        } catch {
            activeCredentialIDs.remove(id)
            throw error
        }
    }
    func endCredentialAttempt(_ id: String) {
        activeCredentialIDs.remove(id)
        lastCredentialCleanup = .distantPast
    }
    /// Connection commits share the mutation queue with settings, refreshes and removal.
    func acceptConnection(_ account: ProviderAccount, snapshot: QuotaSnapshot, replacing original: ProviderAccount?) async throws {
        try await performCredentialMutation { [self] in
            guard !isDemo, localStateReady, let database else { throw StoreError.operation }
            var candidate = state
            let accepted: ProviderAccount
            if let original {
                guard let index = candidate.accounts.firstIndex(where: { $0.id == original.id && $0.generation == original.generation }) else {
                    throw ProviderFailure(message: "This connection changed while signing in. Please reconnect again.")
                }
                let current = candidate.accounts[index]
                accepted = try AccountPolicy.reconnect(original: current, replacement: account)
                candidate.accounts[index] = accepted
                if current.credentialID != accepted.credentialID { candidate.retiredAccounts.append(current) }
            } else {
                guard !candidate.accounts.contains(where: { $0.id == account.id }) else {
                    throw ProviderFailure(message: "This account is already connected.")
                }
                accepted = account
                candidate.accounts.append(accepted)
                candidate.settings.accountOrder.append(accepted.id)
            }
            guard snapshot.belongs(to: accepted) else { throw AccountError.differentIdentity }
            guard !candidate.accounts.contains(where: { $0.id != accepted.id && $0.provider == accepted.provider && $0.subject == accepted.subject && $0.scopeEquals(accepted.scope) }) else {
                throw ProviderFailure(message: "This account is already connected.")
            }
            candidate.snapshots[accepted.id] = snapshot
            candidate.retiredAccounts.removeAll { $0.credentialID == accepted.credentialID }
            try await database.accept(snapshot, account: accepted, state: candidate)
            state = candidate; lastCredentialCleanup = .distantPast
        }
        await reloadHistory()
    }
    func connectDevin(nickname: String, workspace: String, replacing original: ProviderAccount?) async throws {
        let input = (original?.scope ?? workspace).trimmingCharacters(in: .whitespacesAndNewlines)
        let host = DevinUsage.workspace(input)?.host
        guard host != nil || (input.isEmpty && original == nil) else {
            throw ProviderFailure(message: "Enter your company’s Devin Enterprise workspace URL.")
        }
        var account = ProviderAccount(provider: .devin, nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
                                      subject: original?.subject ?? "", scope: host ?? "", unit: .acus, pollingMinutes: 10)
        if let original { account.id = original.id }
        try await stageCredential(provider: .devin, id: account.credentialID)
        defer { endCredentialAttempt(account.credentialID) }
        let snapshot = try await DevinClient.read(account: account, secrets: secrets, interactive: true)
        account.subject = snapshot.subject
        account.scope = snapshot.scope
        try Task.checkCancellation()
        try await acceptConnection(account, snapshot: snapshot, replacing: original)
    }

    func connectGitHub(nickname: String, token: String, allowance: Decimal?, unit: UsageUnit, organization: String, appTokens: GitHubAppTokens? = nil, replacing original: ProviderAccount?) async throws {
        let identity = try await github.identify(token: token)
        var account = ProviderAccount(provider: .copilot, nickname: nickname, subject: identity.subject,
            scope: organization.isEmpty ? "personal" : "organization:" + organization.lowercased(), allowance: allowance, unit: unit, login: identity.login)
        if let original {
            account.id = original.id
            try AccountPolicy.validateReconnect(original: original, replacement: account)
        }
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

    func refreshByUser() async {
        guard !isRefreshing || canRequestRefresh else { return }
        SoundPlayer.shared.play(settings: state.settings, cue: "refresh")
        await refresh()
    }

    func refresh(force: Bool = true) async {
        let tasks = startRefreshes(force: force)
        for task in tasks { await task.value }
    }

    // Claim all eligible connections before yielding. The monitor can then tick
    // again while provider I/O is pending, without starting duplicate reads.
    @discardableResult
    private func startRefreshes(force: Bool) -> [Task<Void, Never>] {
        guard !isDemo, localStateReady else { return [] }
        let epoch = monitoringEpoch
        let now = Date.now
        var tasks: [Task<Void, Never>] = []
        for account in state.accounts where account.enabled && schedule.shouldRefresh(account.id, now: now, force: force) {
            let credential = account.credentialID
            if refreshingCredentials.contains(credential) {
                if force { pendingRefreshes[credential] = (account, epoch) }
                continue
            }
            refreshingCredentials.insert(credential)
            tasks.append(Task {
                defer { refreshingCredentials.remove(credential) }
                await refresh(account, epoch: epoch)
                while let queued = pendingRefreshes.removeValue(forKey: credential),
                      let current = currentAccount(queued.account, epoch: queued.epoch),
                      schedule.shouldRefresh(current.id, now: .now, force: true) {
                    await refresh(current, epoch: queued.epoch)
                }
            })
        }
        return tasks
    }

    private func currentAccount(_ account: ProviderAccount, epoch: UUID) -> ProviderAccount? {
        guard !isDemo, monitoringEpoch == epoch else { return nil }
        return state.accounts.first {
            $0.enabled && $0.id == account.id && $0.generation == account.generation &&
                $0.credentialID == account.credentialID && $0.provider == account.provider &&
                $0.subject == account.subject && $0.scopeEquals(account.scope)
        }
    }

    private func readQuota(_ account: ProviderAccount) async throws -> QuotaSnapshot {
        if let refreshAccount { return try await refreshAccount(account) }
        switch account.provider {
        case .codex:
            let connection = try await CodexConnection.start(credentialID: account.credentialID)
            do {
                let snapshot = try await connection.snapshot(account: account)
                await connection.close()
                return snapshot
            } catch { await connection.close(); throw error }
        case .copilot:
            let token = try await githubCredentials.accessToken(for: account)
            return try await github.read(account: account, token: token)
        case .devin:
            return try await DevinClient.read(account: account, secrets: secrets, interactive: false)
        case .claude:
            return try await ClaudeClient().refresh(account)
        }
    }

    private func refresh(_ account: ProviderAccount, epoch: UUID) async {
        guard currentAccount(account, epoch: epoch) != nil else { return }
        let response: Result<QuotaSnapshot, Error>
        do {
            let snapshot = try await readQuota(account)
            guard snapshot.belongs(to: account) else { throw AccountError.differentIdentity }
            response = .success(snapshot)
        } catch { response = .failure(error) }

        var historyChanged = false
        await enqueueMutation { [self] in
            guard let current = currentAccount(account, epoch: epoch) else { return }
            var candidate = state
            let prior = candidate.snapshots[current.id]
            var snapshot: QuotaSnapshot
            // Honor provider throttles even when saving locally fails.
            switch response {
            case .success(let result):
                snapshot = result
                schedule.succeeded(snapshot, account: current, now: .now)
            case .failure(let error):
                let failure = error as? ProviderFailure
                let keychainError = error as? SecretStoreError
                schedule.failed(current.id, now: .now, retryAt: failure?.retryAt)
                snapshot = prior ?? QuotaSnapshot(accountID: current.id, subject: current.subject, scope: current.scope, observedAt: .now, windows: [])
                snapshot.health = failure?.health ?? (keychainError != nil ? .permissionRequired : error is AccountError ? .authenticationRequired : .offline)
                snapshot.message = failure?.message ?? keychainError?.localizedDescription ?? "Refresh failed. Last known values are retained."
            }

            let alerts = AlertEvaluator.evaluate(account: current, previous: prior, current: snapshot, settings: candidate.settings, now: .now)
            var freshAlerts: [AlertEvent] = []
            for alert in alerts where !candidate.alerts.contains(where: { $0.id == alert.id }) {
                candidate.alerts.append(alert)
                freshAlerts.append(alert)
            }
            candidate.snapshots[current.id] = snapshot
            do {
                guard let database else { throw StoreError.operation }
                if snapshot.health == .healthy {
                    try await database.accept(snapshot, account: current, state: candidate)
                    historyChanged = true
                } else { try await database.save(candidate) }
                state = candidate
                if !freshAlerts.isEmpty {
                    Task {
                        for alert in freshAlerts { await deliver(alert, account: current, epoch: epoch) }
                    }
                }
            } catch { errorMessage = error.localizedDescription }
        }.value
        if historyChanged { await reloadHistory() }
    }

}

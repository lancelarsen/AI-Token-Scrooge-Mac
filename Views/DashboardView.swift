import SwiftUI

struct DashboardView: View {
    @Environment(AppStore.self) private var store
    @State private var dragging = AccountDragging()
    @State private var showSettings = false
    @State private var refreshRequested = false
    @State private var hostSize = CGSize(width: 1000, height: 800)
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        @Bindable var store = store
        GeometryReader { geometry in
            VStack(spacing: 0) {
                header(wide: geometry.size.width >= 1100)
                Divider().overlay(Theme.border)
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 20) {
                            HorizonView()
                            toolbar
                            if store.accounts.isEmpty { emptyState }
                            ForEach(store.accounts) { account in
                                AccountCard(account: account, wide: geometry.size.width - 64 - (store.state.settings.accountSort == .custom ? 57 : 0) - 56 > 1050)
                                    .id(account.id)
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.accent, lineWidth: store.highlightedAccountID == account.id ? 3 : 0))
                                    .background(AccountDragMarker(id: account.id, dragging: dragging))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.actionAccent, lineWidth: dragging.activeID == account.id && dragging.moving ? 2 : 0))
                                    .shadow(color: .black.opacity(dragging.activeID == account.id && dragging.moving ? 0.35 : 0), radius: 16, y: 8)
                                    .opacity(dragging.activeID == account.id && dragging.moving ? 0.94 : 1)
                                    .offset(y: dragging.offsets[account.id] ?? 0)
                                    .zIndex(dragging.activeID == account.id ? 1 : 0)
                            }
                        }.padding(.horizontal, 32).padding(.top, 24).padding(.bottom, 32)
                    }
                    .task(id: store.accountRevealRequest) {
                        guard let id = store.highlightedAccountID else { return }
                        withAnimation { proxy.scrollTo(id, anchor: .center) }
                        do { try await Task.sleep(for: .seconds(6)) } catch { return }
                        store.highlightedAccountID = nil
                    }
                }
            }.background(Theme.background).foregroundStyle(Color(hex: "#F2F1F5"))
        }.frame(minWidth: 760, minHeight: 600)
        .background(DashboardWindowSizeReader { hostSize = $0 })
        .environment(\.dashboardHostSize, hostSize)
        .environment(dragging)
        .onChange(of: store.accounts.map(\.id)) { dragging.cancel() }
        .onChange(of: store.state.settings.accountSort) { dragging.cancel() }
        .onDisappear { dragging.cancel() }
        .preferredColorScheme(.dark).tint(Theme.accent)
        .overlay(alignment: .bottomTrailing) { if let alert = store.activeAlert { AlertBannerView(alert: alert) } }
        .sheet(item: $store.selectedAccount) { account in AccountSettingsView(accountID: account.id, hostSize: hostSize).environment(store) }
        .sheet(isPresented: $showSettings) { SettingsView().environment(store).environment(\.dashboardHostSize, hostSize) }
        .sheet(isPresented: $store.showConnection) { ConnectionView().environment(store).environment(\.dashboardHostSize, hostSize) }
        .sheet(isPresented: $store.showAlertHistory) { AlertHistoryView().environment(store).environment(\.dashboardHostSize, hostSize) }
        .sheet(isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
            DetailsDialog(close: { store.errorMessage = nil }) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Scrooge Needs Attention").font(Theme.dialogTitleFont).foregroundStyle(Theme.accent)
                    Text(store.errorMessage ?? "")
                }
            }
        }
        .task {
            store.openDashboard = { openWindow(id: "dashboard"); NSApp.activate(ignoringOtherApps: true) }
            await store.load()
        }
    }
    private func header(wide: Bool) -> some View {
        let layout = wide ? AnyLayout(HStackLayout(spacing: 24)) : AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
        return layout {
            HStack(spacing: 14) {
                if let url = Bundle.main.url(forResource: "token_baron", withExtension: "png"), let mascot = NSImage(contentsOf: url) {
                    Image(nsImage: mascot).resizable().scaledToFit().frame(width: 66, height: 66)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("AI Token Scrooge").font(.reference(size: 32, weight: .semibold)).frame(height: 40)
                    Text("Never Waste a Token! Never Miss a Reset!").font(.reference(size: 16)).foregroundStyle(Theme.accent).frame(height: 26)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 14) {
                Text(freshness)
                    .font(.reference(size: 12)).foregroundStyle(Theme.secondary).frame(maxWidth: .infinity, alignment: .trailing)
                Button {
                    refreshRequested = true
                    Task {
                        defer { refreshRequested = false }
                        await store.refresh()
                    }
                } label: {
                    HStack(spacing: 10) {
                        if refreshRequested || store.isRefreshing {
                            ProgressView().controlSize(.small).tint(.white).frame(width: 19, height: 19)
                        } else { ActionIcon(symbol: "arrow.clockwise", size: 19) }
                        Text(refreshRequested || store.isRefreshing ? "Refreshing…" : "Refresh")
                    }
                }
                .buttonStyle(ScroogeButtonStyle(processing: refreshRequested || store.isRefreshing))
                .disabled(refreshRequested || store.isRefreshing).accessibilityIdentifier("refreshButton")
                Button { showSettings = true } label: { ActionLabel(title: "Settings", symbol: "gearshape") }.accessibilityIdentifier("settingsButton")
            }.frame(maxWidth: wide ? 500 : .infinity).buttonStyle(ScroogeButtonStyle())
        }.padding(.horizontal, 32).padding(.vertical, 18)
    }
    private var freshness: String {
        var text = store.isDemo ? "DEMO DATA · Live monitoring paused" : store.state.snapshots.values.map(\.observedAt).max().map {
            Format.updated($0, zone: store.state.settings.zone)
        } ?? "Connect an account to start monitoring"
        if !store.isDemo && (!store.state.retiredAccounts.isEmpty || !store.state.retiredCredentialIDs.isEmpty) {
            text += " · Previous Sign-in Cleanup Pending"
        }
        return text
    }
    private var toolbar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 0) {
                ForEach(AccountSort.allCases, id: \.self) { sort in
                    Button { store.edit { AccountPolicy.selectSort(sort, state: &$0) } } label: {
                        HStack(spacing: 9) {
                            ActionIcon(symbol: icon(sort), size: 20)
                            Text(sort.rawValue).font(ReferenceTypography.nativeTextFont(size: 13))
                                .multilineTextAlignment(.center)
                        }.padding(.horizontal, 8).frame(maxWidth: .infinity, minHeight: 44)
                    }.buttonStyle(ScroogeButtonStyle(selected: store.state.settings.accountSort == sort, segmented: true))
                        .accessibilityAddTraits(store.state.settings.accountSort == sort ? .isSelected : [])
                        .overlay(alignment: .trailing) { if sort != AccountSort.allCases.last { Rectangle().fill(Color(hex: "#45464D")).frame(width: 1) } }
                }
            }.clipShape(RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#45464D")))
            Button { if store.isDemo { store.exitDemo() } else { store.showConnection = true } } label: {
                ActionLabel(title: store.isDemo ? "Exit demo" : "Add account", symbol: store.isDemo ? "arrow.up.right.square" : "plus")
            }.buttonStyle(ScroogeButtonStyle()).accessibilityIdentifier("addAccountButton")
        }
    }
    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Your AI capacity, in one quiet place.").font(.reference(size: 24, weight: .semibold)).frame(minHeight: 32, alignment: .leading)
            Text("Connect OpenAI Codex or GitHub Copilot to see usage, upcoming resets and earned-reset expirations.").font(.reference(size: 14)).foregroundStyle(Theme.secondary)
            Button { store.enterDemo() } label: { ActionLabel(title: "Explore with demo data", symbol: "arrow.up.right.square").frame(maxWidth: .infinity, alignment: .leading) }.buttonStyle(ScroogeButtonStyle()).accessibilityIdentifier("exploreDemoButton")
        }.padding(.horizontal, 24).padding(.vertical, 36).frame(maxWidth: .infinity, alignment: .leading)
    }
    private func icon(_ sort: AccountSort) -> String {
        switch sort { case .custom: "circle.grid.3x3.fill"; case .mostRemaining: "battery.100percent"; case .leastRemaining: "battery.25percent"; case .nextReset: "clock" }
    }
}

struct AccountCard: View {
    @Environment(AppStore.self) private var store
    @Environment(AccountDragging.self) private var dragging
    let account: ProviderAccount
    let wide: Bool
    private var snapshot: QuotaSnapshot? { store.state.snapshots[account.id] }
    @State private var showIdentityDetails = false
    private var hasQuotaDetails: Bool {
        account.enabled && snapshot?.belongs(to: account) == true && snapshot?.windows.isEmpty == false
    }
    var body: some View {
        HStack(spacing: 0) {
            if store.state.settings.accountSort == .custom {
                ActionIcon(symbol: "account.reorder", size: 25).frame(width: 56, height: 44).contentShape(Rectangle())
                    .overlay(AccountDragGrip(label: reorderDescription) { event in
                        let ids = store.accounts.map(\.id)
                        dragging.begin(id: account.id, ids: ids, event: event) { slot in
                            await store.moveAccount(account.id, to: slot, expectedOrder: ids)
                        }
                    })
                    .modifier(ImmediateReferenceTooltip(text: reorderDescription))
                    .accessibilityLabel(reorderDescription)
                Rectangle().fill(Theme.border).frame(width: 1).padding(.vertical, 14)
            }
            if hasQuotaDetails {
                let layout = wide ? AnyLayout(HStackLayout(spacing: 12)) : AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
                layout {
                    identity.frame(width: wide ? 220 : nil, alignment: .leading)
                    VStack(spacing: 4) {
                        if let snapshot {
                            ForEach(snapshot.windows) { window in QuotaRow(account: account, window: window, snapshot: snapshot, wide: wide) }
                        }
                    }
                }.padding(.leading, 20).padding(.trailing, 16).padding(.vertical, 8)
            } else {
                Button { store.selectedAccount = account } label: {
                    DialogActionLabel(title: accountStatus)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .padding(.vertical, 10)
                }.buttonStyle(ScroogeButtonStyle())
            }
            Button { store.selectedAccount = account } label: { ActionIcon(symbol: "gearshape", size: 20).frame(width: 44, height: 44) }.buttonStyle(ScroogeButtonStyle(segmented: true)).clipShape(RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#45464D"))).modifier(ImmediateReferenceTooltip(text: settingsDescription))
                .accessibilityLabel(settingsDescription)
                .padding(.top, 14).padding(.trailing, 12).frame(maxHeight: .infinity, alignment: .top)
        }.background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 13)).overlay(RoundedRectangle(cornerRadius: 13).stroke(Theme.border))
            .sheet(isPresented: $showIdentityDetails) {
                AccountUsageDialog(accountID: account.id, windowID: snapshot?.windows.first?.id, close: { showIdentityDetails = false })
            }
    }
    private var reorderDescription: String {
        "Drag \(account.provider.rawValue) / \(store.state.settings.privacy ? "Account" : account.nickname) to Reorder Accounts"
    }
    private var settingsDescription: String {
        "Settings for \(account.provider.rawValue) / \(store.state.settings.privacy ? "Account" : account.nickname) · \(Format.plan(account.provider, snapshot?.planType))"
    }
    private var accountStatus: String {
        let name = store.state.settings.privacy ? "Account" : account.nickname
        let status = !account.enabled ? "Monitoring disabled" :
            (snapshot?.belongs(to: account) == true ? snapshot?.message : nil) ?? "Waiting for usage data"
        return "\(account.provider.rawValue) / \(name) · \(status) · Manage account"
    }
    private var identity: some View {
        Button {
            if hasQuotaDetails { showIdentityDetails = true }
            else { store.selectedAccount = account }
        } label: {
            HStack(spacing: 16) {
                ProviderIcon(provider: account.provider, size: 44)
                VStack(alignment: .leading, spacing: 5) {
                    Text(account.provider.rawValue).font(.reference(size: 20, weight: .semibold))
                    Text("\(store.state.settings.privacy ? "Account" : account.nickname) · \(Format.plan(account.provider, snapshot?.planType))")
                        .font(.reference(size: 12)).foregroundStyle(Theme.accent).padding(.horizontal, 11).padding(.vertical, 3)
                        .background(Color(hex: "#2C293E")).clipShape(Capsule()).overlay(Capsule().stroke(Color(hex: "#51476D")))
                }
            }
        }.buttonStyle(.plain)
            .accessibilityLabel("\(account.provider.rawValue), \(store.state.settings.privacy ? "Account" : account.nickname) · \(Format.plan(account.provider, snapshot?.planType)). Open details.")
    }
}

struct QuotaRow: View {
    @Environment(AppStore.self) private var store
    let account: ProviderAccount
    let window: QuotaWindow
    let snapshot: QuotaSnapshot
    let wide: Bool
    @State private var showDetails = false
    var body: some View {
        Group {
            if wide {
                HStack(spacing: 12) { quotaDetailsButton; usageControls; resetDetailsButton.frame(width: 200, alignment: .leading) }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 12) {
                        quotaDetailsButton.frame(maxWidth: .infinity, alignment: .leading)
                        if window.resetsAt != nil {
                            resetDetailsButton.frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    usageControls
                }
            }
        }
        .frame(minHeight: 56)
        .sheet(isPresented: $showDetails) {
            AccountUsageDialog(accountID: account.id, windowID: window.id, close: { showDetails = false })
        }
    }
    private var quotaDetailsButton: some View {
        Button { showDetails = true } label: {
            quotaLabel.contentShape(Rectangle())
        }.buttonStyle(.plain)
            .accessibilityLabel("\(Format.windowTitle(window.name)). Open Details")
    }
    @ViewBuilder private var resetDetailsButton: some View {
        if window.resetsAt != nil {
            Button { showDetails = true } label: {
                resetCountdown.contentShape(Rectangle())
            }.buttonStyle(.plain)
                .accessibilityLabel("Reset for \(Format.windowTitle(window.name)). Open Details")
        } else {
            Color.clear.frame(height: 0).accessibilityHidden(true)
        }
    }
    private var quotaNote: String {
        if !account.enabled { return "Monitoring Disabled" }
        if snapshot.health == .demo { return "Demo data" }
        if snapshot.health != .healthy {
            let name = snapshot.health.rawValue
            let status = name.prefix(1).uppercased() + name.dropFirst()
            return "\(status): \(snapshot.message ?? "")"
        }
        if snapshot.usageAllowed == false { return "Provider reports usage is paused" }
        if account.provider == .claude || snapshot.message == "Allowance reported by GitHub; billing usage may lag." { return "" }
        return snapshot.message ?? (window.allowanceSource == .manual ? "User-entered allowance · Billing data may lag" : "")
    }
    private var quotaLabel: some View {
        VStack(alignment: .leading, spacing: 4) {
                Text(Format.windowTitle(window.name)).font(.reference(size: 14)).foregroundStyle(Color(hex: "#BEC1D2"))
                if !quotaNote.isEmpty {
                    Text(quotaNote).font(.reference(size: 11)).foregroundStyle(Color(hex: "#A5A8BA"))
                }
            }.frame(width: wide ? 156 : nil, alignment: .leading)
    }
    private var usageControls: some View {
            HStack(spacing: 8) {
                HStack(spacing: 0) {
                    ForEach([true, false], id: \.self) { enabled in
                        if !enabled { Rectangle().fill(Color(hex: "#45464D")).frame(width: 1, height: 46) }
                        Button {
                            if store.state.settings.capacityAlertsEnabled(accountID: account.id, windowID: window.id) != enabled {
                                store.toggleCapacity(account: account.id, window: window.id)
                            }
                        } label: {
                            ActionIcon(symbol: enabled ? "bell.badge" : "bell.slash", size: 22)
                                .frame(width: 39, height: 46)
                        }.buttonStyle(ScroogeButtonStyle(selected: store.state.settings.capacityAlertsEnabled(accountID: account.id, windowID: window.id) == enabled, segmented: true))
                            .accessibilityAddTraits(store.state.settings.capacityAlertsEnabled(accountID: account.id, windowID: window.id) == enabled ? .isSelected : [])
                            .modifier(ImmediateReferenceTooltip(text: "Alarms \(enabled ? "On" : "Off") · Row Alerts · \(account.provider.rawValue) / \(store.state.settings.privacy ? "Account" : account.nickname) · \(Format.plan(account.provider, snapshot.planType)) · \(Format.windowTitle(window.name))"))
                            .accessibilityLabel("\(enabled ? "Enable" : "Disable") Alerts for \(Format.windowTitle(window.name))")
                    }
                }.padding(1)
                    .background(Theme.control)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color(hex: "#45464D")))
                UsageBar(window: window, provider: account.provider, alertsEnabled: store.state.settings.capacityAlertsEnabled(accountID: account.id, windowID: window.id), thresholds: store.state.settings.rule(accountID: account.id, windowID: window.id).thresholds ?? store.state.settings.thresholds,
                         changed: { store.setThresholds(account: account.id, window: window.id, thresholds: $0) }, details: { showDetails = true })
                    .frame(minWidth: 180)
            }
    }
    @ViewBuilder private var resetCountdown: some View {
        if window.resetsAt != nil {
            TimelineView(.periodic(from: .now, by: 30)) { context in
                let now = store.isDemo ? store.presentationDate : context.date
                let enabled = store.state.settings.capacityAlertsEnabled(accountID: account.id, windowID: window.id)
                let severity = enabled ? window.resetsAt.flatMap { TimedReminder.due(store.state.settings.quotaRefreshReminders, at: $0, now: now)?.severity } : nil
                let clockColor: Color = switch severity {
                case .critical: Color(hex: "#F05B69")
                case .warning: Color(hex: "#F2C94C")
                case .info: Color(hex: "#58A6FF")
                case nil: Color(hex: "#B5A0F4")
                }
                HStack(alignment: .top, spacing: 12) {
                    ActionIcon(symbol: "clock", size: 25)
                        .environment(\.actionForeground, clockColor)
                        .padding(.top, 3)
                    ResetCountdownText(date: window.resetsAt, now: now, zone: store.state.settings.zone)
                }.frame(width: wide ? 200 : nil, alignment: .leading)
            }
        }
    }

}

struct QuotaDetailsView: View {
    @Environment(AppStore.self) private var store
    let account: ProviderAccount
    let window: QuotaWindow
    let snapshot: QuotaSnapshot
    private var sourceNote: String {
        if snapshot.health == .demo { return "Demo data" }
        if snapshot.health != .healthy {
            let status = snapshot.health.rawValue
            return "\(status.prefix(1).uppercased() + status.dropFirst()): \(snapshot.message ?? "")"
        }
        if snapshot.usageAllowed == false { return "Provider reports usage is paused" }
        return snapshot.message ?? (window.allowanceSource == .manual ? "User-entered allowance · Billing data may lag" : "")
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(account.provider.rawValue) / \(store.state.settings.privacy ? "Account" : account.nickname) · \(Format.plan(account.provider, snapshot.planType))").font(Theme.dialogTitleFont).foregroundStyle(Theme.accent).frame(minHeight: 32, alignment: .leading)
            Text(Format.windowTitle(window.name)).frame(minHeight: 19, alignment: .leading)
            Text("\(Format.usageText(window, provider: account.provider).used) · \(Format.usageText(window, provider: account.provider).left)").frame(minHeight: 19, alignment: .leading)
            DetailLine(label: "Resets", value: Format.detailDate(window.resetsAt, zone: store.state.settings.zone))
            Color.clear.frame(height: 6)
            if !store.state.settings.privacy {
                DetailLine(label: "Account", value: account.login ?? account.subject)
                DetailLine(label: "Scope", value: account.scope)
            }
            DetailLine(label: "Last successful fetch", value: Format.detailDate(snapshot.observedAt, zone: store.state.settings.zone))
                .lineLimit(1).minimumScaleFactor(0.9)
            DetailLine(label: "Provider data as of", value: Format.detailDate(snapshot.providerDataAt, zone: store.state.settings.zone))
            if !sourceNote.isEmpty {
                Color.clear.frame(height: 6)
                Text(sourceNote).foregroundStyle(Theme.dialogText).frame(minHeight: 19, alignment: .leading)
            }
            if !store.isDemo, account.usageURL != nil {
                Color.clear.frame(height: 6)
                Text("Provider pages use your browser's sign-in. Check its account and workspace before comparing.")
                    .font(Theme.dialogBodyFont).foregroundStyle(Theme.dialogText)
            }
        }.font(Theme.dialogBodyFont).foregroundStyle(Theme.dialogText).textSelection(.enabled).frame(maxWidth: 440, alignment: .leading).preferredColorScheme(.dark)
    }
}

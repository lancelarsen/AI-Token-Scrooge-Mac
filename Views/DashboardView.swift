import SwiftUI

struct DashboardView: View {
    @Environment(AppStore.self) private var store
    @State private var showSettings = false
    @State private var refreshRequested = false
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
                                    .dropDestination(for: String.self) { items, _ in
                                        guard let id = items.first, store.state.accounts.contains(where: { $0.id == id }), store.state.settings.accountSort == .custom else { return false }
                                        store.reorder(id, before: account.id); return true
                                    }
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
        .preferredColorScheme(.dark).tint(Theme.accent)
        .overlay(alignment: .bottomTrailing) { if let alert = store.activeAlert { AlertBannerView(alert: alert) } }
        .sheet(item: $store.selectedAccount) { account in AccountSettingsView(accountID: account.id).environment(store) }
        .sheet(isPresented: $showSettings) { SettingsView().environment(store) }
        .sheet(isPresented: $store.showConnection) { ConnectionView().environment(store) }
        .sheet(isPresented: $store.showAlertHistory) { AlertHistoryView().environment(store) }
        .sheet(isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
            DetailsDialog(close: { store.errorMessage = nil }) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Scrooge Needs Attention").font(.system(size: 20, weight: .semibold)).foregroundStyle(.white)
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
                VStack(alignment: .leading, spacing: 3) {
                    Text("AI Token Scrooge").font(.system(size: 32, weight: .semibold))
                    Text("Never Waste a Token! Never Miss a Reset!").font(.system(size: 16)).foregroundStyle(Theme.accent)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 14) {
                Text(freshness)
                    .font(.system(size: 12)).foregroundStyle(Theme.secondary).frame(maxWidth: .infinity, alignment: .trailing)
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
                .buttonStyle(ScroogeButtonStyle(selected: refreshRequested || store.isRefreshing))
                .disabled(refreshRequested || store.isRefreshing).accessibilityIdentifier("refreshButton")
                Button { showSettings = true } label: { ActionLabel(title: "Settings", symbol: "gearshape") }.accessibilityIdentifier("settingsButton")
            }.frame(maxWidth: wide ? 500 : .infinity).buttonStyle(ScroogeButtonStyle())
        }.padding(.horizontal, 32).padding(.vertical, 18)
    }
    private var freshness: String {
        var text = store.isDemo ? "DEMO DATA · Live Monitoring Paused" : store.state.snapshots.values.map(\.observedAt).max().map {
            Format.updated($0, zone: store.state.settings.zone)
        } ?? "Connect an Account to Start Monitoring"
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
                        HStack(spacing: 10) { ActionIcon(symbol: icon(sort), size: 20); Text(sort.rawValue).font(.system(size: 13)) }.frame(maxWidth: .infinity, minHeight: 44)
                    }.buttonStyle(ScroogeButtonStyle(selected: store.state.settings.accountSort == sort, segmented: true))
                        .overlay(alignment: .trailing) { if sort != AccountSort.allCases.last { Rectangle().fill(Theme.border).frame(width: 1) } }
                }
            }.clipShape(RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border))
            Button { if store.isDemo { store.exitDemo() } else { store.showConnection = true } } label: {
                ActionLabel(title: store.isDemo ? "Exit Demo" : "Add Account", symbol: store.isDemo ? "arrow.up.forward.square" : "plus")
            }.buttonStyle(ScroogeButtonStyle()).accessibilityIdentifier("addAccountButton")
        }
    }
    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Your AI capacity, in one quiet place.").font(.system(size: 24, weight: .semibold))
            Text("Connect OpenAI Codex, GitHub Copilot, or Claude to see usage, upcoming resets and earned-reset expirations.").font(.system(size: 14)).foregroundStyle(Theme.secondary)
            Button { store.enterDemo() } label: { ActionLabel(title: "Explore with demo data", symbol: "arrow.up.right.square").frame(maxWidth: .infinity, alignment: .leading) }.buttonStyle(ScroogeButtonStyle()).accessibilityIdentifier("exploreDemoButton")
        }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
    }
    private func icon(_ sort: AccountSort) -> String {
        switch sort { case .custom: "circle.grid.3x3.fill"; case .mostRemaining: "battery.100percent"; case .leastRemaining: "battery.25percent"; case .nextReset: "clock" }
    }
}

struct AccountCard: View {
    @Environment(AppStore.self) private var store
    let account: ProviderAccount
    let wide: Bool
    private var snapshot: QuotaSnapshot? { store.state.snapshots[account.id] }
    var body: some View {
        HStack(spacing: 0) {
            if store.state.settings.accountSort == .custom {
                ActionIcon(symbol: "account.reorder", size: 17).frame(width: 56, height: 44).contentShape(Rectangle()).draggable(account.id).help("Drag to Reorder Account")
                    .accessibilityLabel("Reorder \(store.state.settings.privacy ? "Account" : account.nickname)")
                Rectangle().fill(Theme.border).frame(width: 1).padding(.vertical, 14)
            }
            let layout = wide ? AnyLayout(HStackLayout(spacing: 12)) : AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            layout {
                identity.frame(width: wide ? 220 : nil, alignment: .leading)
                VStack(spacing: 4) {
                    if account.enabled, let snapshot, snapshot.belongs(to: account), !snapshot.windows.isEmpty {
                        ForEach(snapshot.windows) { window in QuotaRow(account: account, window: window, snapshot: snapshot, wide: wide) }
                    } else { Text(!account.enabled ? "Monitoring Disabled" : snapshot?.message ?? "Waiting for Usage Data").foregroundStyle(Theme.secondary).frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 16) }
                }
            }.padding(.leading, 20).padding(.trailing, 16).padding(.vertical, 8)
            Button { store.selectedAccount = account } label: { ActionIcon(symbol: "gearshape", size: 20).frame(width: 44, height: 44) }.buttonStyle(ScroogeButtonStyle(segmented: true)).clipShape(RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border)).help("Manage \(store.state.settings.privacy ? "Account" : account.nickname)")
                .padding(.top, 14).padding(.trailing, 12).frame(maxHeight: .infinity, alignment: .top)
        }.background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 13)).overlay(RoundedRectangle(cornerRadius: 13).stroke(Theme.border))
    }
    private var identity: some View {
        Button { store.selectedAccount = account } label: {
            HStack(spacing: 16) {
                ProviderIcon(provider: account.provider, size: 44)
                VStack(alignment: .leading, spacing: 5) {
                    Text(account.provider.rawValue).font(.system(size: 20, weight: .semibold))
                    Text("\(store.state.settings.privacy ? "Account" : account.nickname) · \(Format.plan(account.provider, snapshot?.planType))")
                        .font(.system(size: 12)).foregroundStyle(Theme.accent).padding(.horizontal, 11).padding(.vertical, 3)
                        .background(Theme.accent.opacity(0.12)).clipShape(Capsule()).overlay(Capsule().stroke(Theme.accent.opacity(0.3)))
                }
            }
        }.buttonStyle(.plain)
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
                HStack(spacing: 12) { quotaLabel; usageControls; resetCountdown }
            } else {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .top, spacing: 12) {
                        quotaLabel.frame(maxWidth: .infinity, alignment: .leading)
                        resetCountdown.frame(maxWidth: .infinity, alignment: .leading)
                    }
                    usageControls
                }
            }
        }
        .sheet(isPresented: $showDetails) {
            DetailsDialog(width: 342, close: { showDetails = false }) {
                QuotaDetailsView(account: account, window: window, snapshot: snapshot)
            }
        }
    }
    private var quotaLabel: some View {
VStack(alignment: .leading, spacing: 5) {
                Text(window.name).font(.system(size: 14))
                Text(!account.enabled ? "Monitoring Disabled" : snapshot.health == .demo ? "Demo Data" : snapshot.health == .healthy ? "" : snapshot.message ?? snapshot.health.rawValue)
                    .font(.system(size: 11)).foregroundStyle(Theme.secondary)
            }.frame(width: wide ? 156 : nil, alignment: .leading)
    }
    private var usageControls: some View {
            HStack(spacing: 10) {
                HStack(spacing: 0) {
                    ForEach([true, false], id: \.self) { enabled in
                        Button {
                            if store.state.settings.capacityAlertsEnabled(accountID: account.id, windowID: window.id) != enabled {
                                store.toggleCapacity(account: account.id, window: window.id)
                            }
                        } label: {
                            ActionIcon(symbol: enabled ? "bell.badge" : "bell.slash", size: 22)
                                .frame(width: 40, height: 46)
                        }.buttonStyle(ScroogeButtonStyle(selected: store.state.settings.capacityAlertsEnabled(accountID: account.id, windowID: window.id) == enabled, segmented: true))
                            .accessibilityAddTraits(store.state.settings.capacityAlertsEnabled(accountID: account.id, windowID: window.id) == enabled ? .isSelected : [])
                            .help("Alarms \(enabled ? "On" : "Off") · Row Alerts · \(account.provider.rawValue) / \(store.state.settings.privacy ? "Account" : account.nickname) · \(Format.plan(account.provider, snapshot.planType)) · \(window.name)")
                            .accessibilityLabel("\(enabled ? "Enable" : "Disable") Alerts for \(window.name)")
                    }
                }.clipShape(RoundedRectangle(cornerRadius: 9))
                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(Theme.border))
                UsageBar(window: window, alertsEnabled: store.state.settings.capacityAlertsEnabled(accountID: account.id, windowID: window.id), thresholds: store.state.settings.rule(accountID: account.id, windowID: window.id).thresholds ?? store.state.settings.thresholds,
                         changed: { store.setThresholds(account: account.id, window: window.id, thresholds: $0) }, details: { showDetails = true })
                    .frame(minWidth: 180)
            }
    }
    private var resetCountdown: some View {
TimelineView(.periodic(from: .now, by: 30)) { context in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 12) {
                            let enabled = store.state.settings.capacityAlertsEnabled(accountID: account.id, windowID: window.id)
                            let severity = enabled ? window.resetsAt.flatMap { TimedReminder.due(store.state.settings.quotaRefreshReminders, at: $0, now: context.date)?.severity } : nil
                            let clockColor: Color = switch severity {
                            case .critical: Color(hex: "#F05B69")
                            case .warning: Color(hex: "#F2C94C")
                            case .info: Color(hex: "#58A6FF")
                            case nil: Theme.accent
                            }
                            Image(systemName: "clock").font(.system(size: 23)).foregroundStyle(clockColor)
                            Text(Format.countdown(window.resetsAt, now: context.date)).font(.system(size: 20, weight: .semibold)).foregroundStyle(Theme.accent)
                        }
                        Text(Format.date(window.resetsAt, zone: store.state.settings.zone)).font(.system(size: 12)).foregroundStyle(Theme.secondary).padding(.leading, 35)
                    }.frame(width: wide ? 200 : nil, alignment: .leading)
                }
    }

}

struct QuotaDetailsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.openURL) private var openURL
    let account: ProviderAccount
    let window: QuotaWindow
    let snapshot: QuotaSnapshot
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(account.provider.rawValue) / \(store.state.settings.privacy ? "Account" : account.nickname) · \(Format.plan(account.provider, snapshot.planType))").font(.system(size: 21, weight: .semibold)).foregroundStyle(Theme.accent)
            Text(window.name)
            Text("\(Format.percent(window.usedPercent)) used · \(Format.percent(window.remainingPercent)) left")
            if let used = window.used, window.unit != .percent { DetailLine(label: "Used", value: "\(NSDecimalNumber(decimal: used).stringValue) \(window.unit.rawValue)") }
            if let limit = window.limit, window.unit != .percent { DetailLine(label: "Allowance", value: "\(NSDecimalNumber(decimal: limit).stringValue) · \(window.allowanceSource.rawValue.capitalized)") }
            DetailLine(label: "Resets", value: Format.detailDate(window.resetsAt, zone: store.state.settings.zone))
            Color.clear.frame(height: 6)
            if !store.state.settings.privacy {
                DetailLine(label: "Account", value: account.login ?? account.subject)
                DetailLine(label: "Scope", value: account.scope)
            }
            DetailLine(label: "Last successful fetch", value: Format.detailDate(snapshot.observedAt, zone: store.state.settings.zone))
            DetailLine(label: "Provider data as of", value: Format.detailDate(snapshot.providerDataAt, zone: store.state.settings.zone))
            if snapshot.health == .demo {
                Color.clear.frame(height: 6)
                Text("Demo data")
            } else if let message = snapshot.message, !message.isEmpty {
                Color.clear.frame(height: 6)
                Text(message).foregroundStyle(Theme.secondary)
            }
            if !store.isDemo, let url = account.usageURL {
                Text("Provider pages use your browser’s sign-in. Check its account and workspace before comparing.").font(.caption).foregroundStyle(Theme.secondary)
                Button("Open Provider Usage") {
                    openURL(url) { accepted in
                        if !accepted { store.errorMessage = "Provider page unavailable. Open your provider’s usage page in your browser and check its connection status." }
                    }
                }.buttonStyle(ScroogeButtonStyle())
            }
        }.font(.system(size: 14)).foregroundStyle(Theme.secondary).textSelection(.enabled).frame(maxWidth: 440, alignment: .leading).preferredColorScheme(.dark)
    }
}

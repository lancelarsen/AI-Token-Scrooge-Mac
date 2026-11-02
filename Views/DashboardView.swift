import SwiftUI

struct DashboardView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        @Bindable var store = store
        GeometryReader { geometry in
            VStack(spacing: 0) {
                header(wide: geometry.size.width >= 1100)
                Divider().overlay(Theme.border)
                ScrollView {
                    VStack(spacing: 20) {
                        HorizonView()
                        toolbar
                        if store.accounts.isEmpty { emptyState }
                        ForEach(store.accounts) { account in
                            AccountCard(account: account, wide: geometry.size.width > 1200)
                                .dropDestination(for: String.self) { items, _ in
                                    guard let id = items.first, store.state.accounts.contains(where: { $0.id == id }), store.state.settings.accountSort == .custom else { return false }
                                    store.reorder(id, before: account.id); return true
                                }
                        }
                    }.padding(.horizontal, 32).padding(.top, 24).padding(.bottom, 32)
                }
            }.background(Theme.background).foregroundStyle(Color(hex: "#F2F1F5"))
        }.frame(minWidth: 760, minHeight: 600)
        .preferredColorScheme(.dark).tint(Theme.accent)
        .overlay(alignment: .bottomTrailing) { if let alert = store.activeAlert { AlertBannerView(alert: alert) } }
        .sheet(item: $store.selectedAccount) { account in AccountSettingsView(accountID: account.id).environment(store) }
        .sheet(isPresented: $store.showConnection) { ConnectionView().environment(store) }
        .sheet(isPresented: $store.showAlertHistory) { AlertHistoryView().environment(store) }
        .alert("Scrooge Needs Attention", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
            Button("OK") { store.errorMessage = nil }
        } message: { Text(store.errorMessage ?? "") }
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
                Button { Task { await store.refresh() } } label: { ActionLabel(title: "Refresh", symbol: "arrow.clockwise") }
                    .disabled(store.isRefreshing).accessibilityIdentifier("refreshButton")
                Button { openSettings() } label: { ActionLabel(title: "Settings", symbol: "gearshape") }.accessibilityIdentifier("settingsButton")
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
                        HStack(spacing: 10) { Image(systemName: icon(sort)).foregroundStyle(Theme.accent); Text(sort.rawValue).font(.system(size: 12)) }.frame(maxWidth: .infinity, minHeight: 44)
                    }.buttonStyle(.plain).background(store.state.settings.accountSort == sort ? Theme.accent.opacity(0.28) : Theme.control)
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
            Text("Connect OpenAI Codex, GitHub Copilot, or Claude to see usage, upcoming resets and earned-reset expirations.").foregroundStyle(Theme.secondary)
            Button { store.enterDemo() } label: { ActionLabel(title: "Explore with Demo Data", symbol: "chart.xyaxis.line") }.buttonStyle(ScroogeButtonStyle()).accessibilityIdentifier("exploreDemoButton")
        }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
    }
    private func icon(_ sort: AccountSort) -> String {
        switch sort { case .custom: "circle.grid.2x3.fill"; case .mostRemaining: "battery.100percent"; case .leastRemaining: "battery.25percent"; case .nextReset: "clock" }
    }
}

struct AccountCard: View {
    @Environment(AppStore.self) private var store
    let account: ProviderAccount
    let wide: Bool
    private var snapshot: QuotaSnapshot? { store.state.snapshots[account.id] }
    var body: some View {
        HStack(spacing: 16) {
            if store.state.settings.accountSort == .custom {
                Image(systemName: "circle.grid.2x3.fill").foregroundStyle(Theme.accent).draggable(account.id).help("Drag to Reorder Account")
                    .accessibilityLabel("Reorder \(store.state.settings.privacy ? "Account" : account.nickname)")
            }
            let layout = wide ? AnyLayout(HStackLayout(spacing: 20)) : AnyLayout(VStackLayout(alignment: .leading, spacing: 14))
            layout {
                identity.frame(width: wide ? 220 : nil, alignment: .leading)
                VStack(spacing: 8) {
                    if let snapshot, !snapshot.windows.isEmpty {
                        ForEach(snapshot.windows) { window in QuotaRow(account: account, window: window, snapshot: snapshot, wide: wide) }
                    } else { Text(!account.enabled ? "Monitoring Disabled" : snapshot?.message ?? "Waiting for Usage Data").foregroundStyle(Theme.secondary).frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 16) }
                }
            }
            Button { store.selectedAccount = account } label: { ActionLabel(title: "", symbol: "gearshape") }.buttonStyle(ScroogeButtonStyle()).help("Manage \(store.state.settings.privacy ? "Account" : account.nickname)")
        }.padding(.horizontal, 20).padding(.vertical, 12).background(Theme.card)
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
    @Environment(\.openURL) private var openURL
    let account: ProviderAccount
    let window: QuotaWindow
    let snapshot: QuotaSnapshot
    let wide: Bool
    @State private var showDetails = false
    var body: some View {
        let layout = wide ? AnyLayout(HStackLayout(spacing: 12)) : AnyLayout(VStackLayout(alignment: .leading, spacing: 7))
        layout {
            VStack(alignment: .leading, spacing: 5) {
                Text(window.name).font(.system(size: 14))
                Text(!account.enabled ? "Monitoring Disabled" : snapshot.health == .demo ? "Demo Data" : snapshot.health == .healthy ? "" : snapshot.message ?? snapshot.health.rawValue)
                    .font(.system(size: 11)).foregroundStyle(Theme.secondary)
            }.frame(width: wide ? 150 : nil, alignment: .leading)
            HStack(spacing: 10) {
                Button { store.toggleCapacity(account: account.id, window: window.id) } label: {
                    Image(systemName: store.state.settings.capacityAlertsEnabled(accountID: account.id, windowID: window.id) ? "bell.badge" : "bell.slash")
                        .font(.system(size: 20)).foregroundStyle(Theme.accent).frame(width: 48, height: 46)
                        .background(Theme.accent.opacity(0.15)).clipShape(RoundedRectangle(cornerRadius: 9))
                }.buttonStyle(.plain).help("Toggle Alerts for \(window.name)")
                UsageBar(window: window, thresholds: store.state.settings.rule(accountID: account.id, windowID: window.id).thresholds ?? store.state.settings.thresholds,
                         changed: { store.setThresholds(account: account.id, window: window.id, thresholds: $0) }, details: { showDetails = true })
                    .frame(minWidth: 180)
                TimelineView(.periodic(from: .now, by: 30)) { context in
                    VStack(alignment: .leading, spacing: 5) {
                        Label(Format.countdown(window.resetsAt, now: context.date), systemImage: "clock").font(.system(size: 18, weight: .medium)).foregroundStyle(Theme.accent)
                        Text(Format.date(window.resetsAt, zone: store.state.settings.zone)).font(.system(size: 11)).foregroundStyle(Theme.secondary)
                    }.frame(width: 165, alignment: .leading)
                }
            }
        }
        .popover(isPresented: $showDetails) {
            VStack(alignment: .leading, spacing: 12) {
                Text(window.name).font(.title2)
                Text("\(Format.percent(window.usedPercent)) Used / \(Format.percent(window.remainingPercent)) Left")
                if let used = window.used, window.unit != .percent { Text("Used: \(NSDecimalNumber(decimal: used).stringValue) \(window.unit.rawValue)") }
                if let limit = window.limit { Text("Allowance: \(NSDecimalNumber(decimal: limit).stringValue) · \(window.allowanceSource.rawValue.capitalized)") }
                Text("Resets: \(Format.date(window.resetsAt, zone: store.state.settings.zone))")
                if !store.state.settings.privacy {
                    Text("Account: \(account.login ?? account.subject)")
                    Text("Scope: \(account.scope)")
                }
                Text("Last Successful Fetch: \(Format.date(snapshot.observedAt, zone: store.state.settings.zone))")
                Text("Provider Data As Of: \(Format.date(snapshot.providerDataAt, zone: store.state.settings.zone))")
                if let message = snapshot.message { Text(message).foregroundStyle(Theme.secondary) }
                if !store.isDemo, let url = account.usageURL {
                    Text("Provider pages use your browser’s sign-in. Check its account and workspace before comparing.").font(.caption).foregroundStyle(Theme.secondary)
                    Button("Open Provider Usage") {
                        openURL(url) { accepted in
                            if !accepted { store.errorMessage = "Provider page unavailable. Open your provider’s usage page in your browser and check its connection status." }
                        }
                    }.buttonStyle(ScroogeButtonStyle())
                }
            }.padding(24).frame(maxWidth: 440).preferredColorScheme(.dark)
        }
    }
}

import SwiftUI

struct AccountSettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let accountID: String
    var hostSize = CGSize(width: 1048, height: 864)
    @State private var newColor = Color(hex: "#B5A0F4")
    @State private var showColor = false
    @State private var confirmRemove = false
    @State private var nicknameDraft = ""
    private var panelSize: CGSize {
        CGSize(width: min(1000, max(640, hostSize.width - 48)),
               height: min(800, max(400, hostSize.height - 64)))
    }
    @FocusState private var editingNickname: Bool
    private var account: ProviderAccount? { store.state.accounts.first { $0.id == accountID } }
    private var lineColors: [String] {
        var seen = Set<String>()
        return (Theme.palette + store.state.settings.customColors).filter { seen.insert($0.uppercased()).inserted }
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack { Image(systemName: "person").font(.system(size: 26)).foregroundStyle(Theme.accent); Text(accountTitle).font(.system(size: 26, weight: .semibold)).foregroundStyle(.white); Spacer(); Button { dismiss() } label: { DialogActionLabel(title: "Close", symbol: "xmark") }.buttonStyle(ScroogeButtonStyle()).keyboardShortcut(.cancelAction) }.padding(.horizontal, 20).padding(.vertical, 12)
            ScrollView {
                if let account {
                    VStack(spacing: 12) {
                        SettingsCard(title: "Account", symbol: "person", help: "Account name, history line color, polling interval and monitoring preferences.") {
                            HStack(spacing: 12) {
                                Text("Account Name").frame(width: 190, alignment: .leading)
                                TextField("Personal, Work", text: $nicknameDraft).textFieldStyle(.plain)
                                    .padding(.horizontal, 12).frame(height: 32)
                                    .background(Color(hex: "#2A2B30"), in: RoundedRectangle(cornerRadius: 10))
                                    .overlay(alignment: .bottom) {
                                        Rectangle().fill(editingNickname ? Theme.accent : Theme.secondary.opacity(0.55))
                                            .frame(height: editingNickname ? 2 : 1).padding(.horizontal, 10)
                                    }.accessibilityLabel("Account Name")
                                .focused($editingNickname)
                                .onSubmit { saveNickname() }
                                .onChange(of: editingNickname) { _, focused in if !focused { saveNickname() } }
                            }
                            HStack(alignment: .top, spacing: 12) {
                            Text("Line Color").frame(width: 190, height: 32, alignment: .leading)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 32, maximum: 32), spacing: 8)], alignment: .leading, spacing: 8) {
                                ForEach(lineColors, id: \.self) { hex in
                                    Button { update { $0.lineColor = hex } } label: {
                                        ZStack { RoundedRectangle(cornerRadius: 8).fill(Color(hex: hex)); if account.resolvedLineColor(plan: store.state.snapshots[account.id]?.planType).caseInsensitiveCompare(hex) == .orderedSame { RoundedRectangle(cornerRadius: 8).stroke(.white, lineWidth: 2); Image(systemName: "checkmark").foregroundStyle(.black) } }.frame(width: 32, height: 32)
                                    }.buttonStyle(.plain).accessibilityLabel("Line Color \(hex)")
                                }
                                Button { showColor = true } label: { Image(systemName: "plus").frame(width: 32, height: 32).background(Theme.control).clipShape(RoundedRectangle(cornerRadius: 8)).overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.accent, lineWidth: 1)) }.buttonStyle(.plain).help("Add Custom Color")
                                    .popover(isPresented: $showColor) {
                                        DetailsDialog(closeTitle: "Cancel", primaryTitle: "Add Color", primaryAction: {
                                            let hex = newColor.hex; store.edit { state in
                                                if !state.settings.customColors.contains(hex) { state.settings.customColors.append(hex) }
                                                if let i = state.accounts.firstIndex(where: { $0.id == accountID }) { state.accounts[i].lineColor = hex }
                                            }; showColor = false
                                        }, close: { showColor = false }) {
                                            VStack(alignment: .leading, spacing: 16) {
                                                Text("Add Line Color").font(.system(size: 20, weight: .semibold)).foregroundStyle(.white)
                                                ColorPicker("Line Color", selection: $newColor, supportsOpacity: false)
                                            }
                                        }
                                    }
                            }
                            }
                            HStack(spacing: 12) {
                                HStack(spacing: 6) {
                                infoIcon("How often Scrooge checks this account, from 1 to 30 minutes.")
                                Text("Polling Interval: \(account.effectivePollingMinutes) Min").frame(width: 190, alignment: .leading)
                                    .help("How often Scrooge automatically checks this account for updated usage, from 1 to 30 minutes. Shorter intervals show changes sooner; longer intervals make fewer requests. Changes save automatically.")
                                }
                                MinuteSlider(value: Binding(get: { account.effectivePollingMinutes }, set: { value in update { $0.pollingMinutes = value } })).frame(height: 44)
                            }
                            HStack(spacing: 6) {
                            infoIcon("Pause checks and alerts without removing this connection.")
                            Toggle("Monitor This Account", isOn: Binding(get: { account.enabled }, set: { value in update { $0.enabled = value; $0.generation = UUID() } }))
                                .toggleStyle(ScroogeSwitchStyle()).frame(minHeight: 36)
                                .help("Pause checks and alerts without removing this connection.")
                            }
                        }
                        if let savedSnapshot = store.state.snapshots[accountID], savedSnapshot.belongs(to: account), let reserve = savedSnapshot.reserve {
                            SettingsCard(title: "Available Resets", symbol: "folder", help: "Earned resets reported by this provider and their expiration dates.") {
                                Text("\(reserve.availableCount.map(String.init) ?? "Unknown") Available").font(.system(size: 20))
                                if let credits = reserve.credits {
                                    ForEach(credits) { credit in
                                        Text("Expires \(Format.date(credit.expiresAt, zone: store.state.settings.zone))").foregroundStyle(Theme.amber)
                                    }
                                } else { Text("Credit Details Unavailable").foregroundStyle(Theme.secondary) }
                                if reserve.hasPartialDetails { Text("Provider supplied only partial credit details.").foregroundStyle(Theme.secondary) }
                            }
                        }
                        SettingsCard(title: "Other Alerts", symbol: "desktopcomputer") {
                            Text("Warning and critical levels are adjusted directly on the dashboard bars.").font(.system(size: 13)).foregroundStyle(Theme.secondary)
                            ruleToggle("Capacity Exhausted", path: \.exhausted, help: "Alert when a monitored allowance has no remaining capacity.")
                            ruleToggle("Capacity Restored", path: \.restored, help: "Alert when an exhausted allowance has capacity again and the provider confirms usage is allowed.")
                            ruleToggle("Reset Expiry Reminders", path: \.expiry, help: "Remind you before available earned resets expire.")
                        }
                        SettingsCard(title: "Connection", symbol: "link", help: "Reconnect this account or remove its saved connection.") {
                            Text("Sign in again only if this account needs a new connection. Your saved settings stay in place.").font(.system(size: 13)).foregroundStyle(Theme.secondary)
                            Button { store.reconnectAccountID = accountID; dismiss(); store.showConnection = true } label: { DialogActionLabel(title: "Sign In Again", symbol: "person").frame(maxWidth: .infinity, alignment: .leading) }.buttonStyle(ScroogeButtonStyle()).disabled(store.isDemo)
                            Button(role: .destructive) { confirmRemove = true } label: { DialogActionLabel(title: "Remove Account", symbol: "trash").frame(maxWidth: .infinity, alignment: .leading) }.buttonStyle(ScroogeButtonStyle()).disabled(store.isDemo)
                        }
                    }.padding(.horizontal, 36).padding(.vertical, 12)
                }
            }
        }.font(.system(size: 14)).frame(width: panelSize.width, height: panelSize.height).background(Theme.background).preferredColorScheme(.dark).tint(Theme.accent)
        .onAppear {
            nicknameDraft = account?.nickname ?? ""

        }
        .onDisappear { saveNickname() }
        .sheet(isPresented: $confirmRemove) {
            ConfirmationDetailsDialog(title: "Remove This Account?",
                message: "This removes its local history and Scrooge-owned connection. Your other apps stay signed in.",
                actionTitle: "Remove Account", cancel: { confirmRemove = false }) {
                    confirmRemove = false
                    Task { await store.removeAccount(accountID); dismiss() }
                }
        }
    }
    private var accountTitle: String {
        guard let account else { return "Account Settings" }
        return "\(account.provider.rawValue) / \(store.state.settings.privacy ? "Account" : account.nickname) · \(Format.plan(account.provider, store.state.snapshots[accountID]?.planType))"
    }
    private func saveNickname() {
        guard let account else { return }
        let name = nicknameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { nicknameDraft = account.nickname; return }
        nicknameDraft = name
        if name != account.nickname { update { $0.nickname = name } }
    }
    private func update(_ change: @escaping @MainActor (inout ProviderAccount) -> Void) {
        store.edit { state in if let index = state.accounts.firstIndex(where: { $0.id == accountID }) { change(&state.accounts[index]) } }
    }
    private func ruleToggle(_ title: String, path: WritableKeyPath<AlertRule,Bool>, help: String) -> some View {
        HStack(spacing: 6) {
        infoIcon(help)
        Toggle(title, isOn: Binding(get: { store.state.settings.rule(accountID: accountID)[keyPath: path] }, set: { value in store.edit { state in
            var rule = state.settings.rule(accountID: accountID); rule[keyPath: path] = value; rule.windowID = nil
            state.settings.rules.removeAll { $0.accountID == accountID && $0.windowID == nil }; state.settings.rules.append(rule)
        } })).toggleStyle(ScroogeSwitchStyle()).frame(minHeight: 36).help(help)
        }
    }
    private func infoIcon(_ help: String) -> some View {
        Image(systemName: "info.circle").font(.system(size: 14)).foregroundStyle(Theme.accent)
            .frame(width: 20).help(help).accessibilityLabel(help)
    }
}

struct MinuteSlider: View {
    @Binding var value: Int
    var body: some View {
        GeometryReader { geometry in
            let width = max(0, geometry.size.width - 28)
            let x = 14 + width * Double(value - 1) / 29
            Canvas { context, size in
                let y = size.height / 2
                context.fill(Path(roundedRect: CGRect(x: 14, y: y - 2, width: width, height: 4), cornerRadius: 2), with: .color(Color(hex: "#41434F")))
                context.fill(Path(roundedRect: CGRect(x: 14, y: y - 2, width: max(0, x - 14), height: 4), cornerRadius: 2), with: .color(Color(hex: "#A990ED")))
                for tick in 0..<30 {
                    let position = 14 + width * Double(tick) / 29
                    context.fill(Path(CGRect(x: position - 0.5, y: y - 6, width: 1, height: 12)), with: .color(Color(hex: "#A990ED")))
                }
                context.fill(Path(ellipseIn: CGRect(x: x - 10, y: y - 10, width: 20, height: 20)), with: .color(Color(hex: "#41434F")))
                context.fill(Path(ellipseIn: CGRect(x: x - 5, y: y - 5, width: 10, height: 10)), with: .color(Theme.accent))
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { event in
                guard width > 0 else { return }
                setMinute(Int(((event.location.x - 14) / width * 29).rounded()) + 1)
            })
        }
        .focusable()
        .onKeyPress(.leftArrow) { setMinute(value - 1); return .handled }
        .onKeyPress(.downArrow) { setMinute(value - 1); return .handled }
        .onKeyPress(.rightArrow) { setMinute(value + 1); return .handled }
        .onKeyPress(.upArrow) { setMinute(value + 1); return .handled }
        .onKeyPress(.home) { setMinute(1); return .handled }
        .onKeyPress(.end) { setMinute(30); return .handled }
        .accessibilityLabel("Polling Interval in Minutes, 1 to 30")
        .accessibilityValue("\(value)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: setMinute(value + 1)
            case .decrement: setMinute(value - 1)
            @unknown default: break
            }
        }
    }
    private func setMinute(_ proposed: Int) {
        let next = min(30, max(1, proposed))
        if value != next { value = next }
    }
}

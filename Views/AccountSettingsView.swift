import SwiftUI

struct AccountSettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let accountID: String
    @State private var newColor = Color(hex: "#B5A0F4")
    @State private var showColor = false
    @State private var confirmRemove = false
    @State private var nicknameDraft = ""
    @FocusState private var editingNickname: Bool
    private var account: ProviderAccount? { store.state.accounts.first { $0.id == accountID } }
    private var lineColors: [String] {
        var seen = Set<String>()
        return (Theme.palette + store.state.settings.customColors).filter { seen.insert($0.uppercased()).inserted }
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack { Text("Account Settings").font(.system(size: 26, weight: .semibold)).foregroundStyle(Theme.accent); Spacer(); Button { dismiss() } label: { DialogActionLabel(title: "Close", symbol: "xmark") }.buttonStyle(ScroogeButtonStyle()).keyboardShortcut(.cancelAction) }.padding(24)
            ScrollView {
                if let account {
                    VStack(spacing: 12) {
                        SettingsCard(title: "Account", symbol: "person.crop.circle") {
                            TextField("Account Name", text: $nicknameDraft).textFieldStyle(.roundedBorder)
                                .focused($editingNickname)
                                .onSubmit { saveNickname() }
                                .onChange(of: editingNickname) { _, focused in if !focused { saveNickname() } }
                            Text("Line Color")
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 36, maximum: 40))], alignment: .leading) {
                                ForEach(lineColors, id: \.self) { hex in
                                    Button { update { $0.lineColor = hex } } label: {
                                        ZStack { RoundedRectangle(cornerRadius: 5).fill(Color(hex: hex)); if account.resolvedLineColor(plan: store.state.snapshots[account.id]?.planType).caseInsensitiveCompare(hex) == .orderedSame { Image(systemName: "checkmark").foregroundStyle(.black) } }.frame(width: 32, height: 32)
                                    }.buttonStyle(.plain).accessibilityLabel("Line Color \(hex)")
                                }
                                Button { showColor = true } label: { Image(systemName: "plus").frame(width: 32, height: 32).background(Theme.control).clipShape(RoundedRectangle(cornerRadius: 5)) }.buttonStyle(.plain).help("Add Custom Color")
                                    .popover(isPresented: $showColor) {
                                        DetailsDialog(closeTitle: "Cancel", primaryTitle: "Add Color", primaryAction: {
                                            let hex = newColor.hex; store.edit { state in
                                                if !state.settings.customColors.contains(hex) { state.settings.customColors.append(hex) }
                                                if let i = state.accounts.firstIndex(where: { $0.id == accountID }) { state.accounts[i].lineColor = hex }
                                            }; showColor = false
                                        }, close: { showColor = false }) {
                                            VStack(alignment: .leading, spacing: 16) {
                                                Text("Custom Line Color").font(.system(size: 20, weight: .semibold)).foregroundStyle(.white)
                                                ColorPicker("Line Color", selection: $newColor, supportsOpacity: false)
                                            }
                                        }
                                    }
                            }
                            HStack {
                                Text("Polling Interval: \(account.effectivePollingMinutes) Min").frame(width: 210, alignment: .leading)
                                    .help("How often Scrooge checks this account. The slider snaps to whole minutes.")
                                MinuteSlider(value: Binding(get: { account.effectivePollingMinutes }, set: { value in update { $0.pollingMinutes = value } })).frame(height: 42)
                            }
                            Toggle("Monitor This Account", isOn: Binding(get: { account.enabled }, set: { value in update { $0.enabled = value; $0.generation = UUID() } }))
                                .help("Pause checks and alerts without removing this connection.")
                        }
                        if let savedSnapshot = store.state.snapshots[accountID], savedSnapshot.belongs(to: account), let reserve = savedSnapshot.reserve {
                            SettingsCard(title: "Available Resets", symbol: "hourglass") {
                                Text("\(reserve.availableCount.map(String.init) ?? "Unknown") Reported Available").font(.title2)
                                Text("Snapshot Fetched: \(Format.date(savedSnapshot.observedAt, zone: store.state.settings.zone))")
                                Text(account.enabled ? savedSnapshot.health.rawValue : "Monitoring Paused").foregroundStyle(Theme.secondary)
                                if let credits = reserve.credits {
                                    ForEach(credits) { credit in
                                        Text("\(Format.date(credit.expiresAt, zone: store.state.settings.zone)) · \(credit.expiresAt.map { $0 <= Date() } == true ? "Expired Locally — Checking Provider" : credit.status)")
                                    }
                                } else { Text("Credit Details Unavailable").foregroundStyle(Theme.secondary) }
                                if reserve.hasPartialDetails { Text("Provider supplied only partial credit details.").foregroundStyle(Theme.secondary) }
                            }
                        }
                        SettingsCard(title: "Other Alerts", symbol: "bell") {
                            ruleToggle("Capacity Exhausted", path: \.exhausted, help: "Alert when a monitored allowance has no remaining capacity.")
                            ruleToggle("Capacity Restored", path: \.restored, help: "Alert when an exhausted allowance has capacity again and the provider confirms usage is allowed.")
                            ruleToggle("Reset Expiry Reminders", path: \.expiry, help: "Remind you before available earned resets expire.")
                        }
                        SettingsCard(title: "Connection", symbol: "link") {
                            Text("Sign in again only if this account needs a new connection. Your saved settings stay in place.").foregroundStyle(Theme.secondary)
                            Button("Sign In Again") { store.reconnectAccountID = accountID; dismiss(); store.showConnection = true }.buttonStyle(ScroogeButtonStyle()).disabled(store.isDemo)
                            Button("Remove Account", role: .destructive) { confirmRemove = true }.buttonStyle(ScroogeButtonStyle()).disabled(store.isDemo)
                        }
                    }.padding(24)
                }
            }
        }.frame(width: 760, height: 760).background(Theme.background).preferredColorScheme(.dark).tint(Theme.accent)
        .onAppear { nicknameDraft = account?.nickname ?? "" }
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
        Toggle(title, isOn: Binding(get: { store.state.settings.rule(accountID: accountID)[keyPath: path] }, set: { value in store.edit { state in
            var rule = state.settings.rule(accountID: accountID); rule[keyPath: path] = value; rule.windowID = nil
            state.settings.rules.removeAll { $0.accountID == accountID && $0.windowID == nil }; state.settings.rules.append(rule)
        } })).help(help)
    }
}

struct MinuteSlider: NSViewRepresentable {
    @Binding var value: Int
    func makeNSView(context: Context) -> NSSlider {
        let slider = NSSlider(value: Double(value), minValue: 1, maxValue: 30, target: context.coordinator, action: #selector(Coordinator.changed(_:)))
        slider.numberOfTickMarks = 30; slider.allowsTickMarkValuesOnly = true; slider.tickMarkPosition = .below
        slider.isContinuous = true; slider.setAccessibilityLabel("Polling Interval in Minutes")
        return slider
    }
    func updateNSView(_ slider: NSSlider, context: Context) { context.coordinator.parent = self; if slider.integerValue != value { slider.integerValue = value } }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    @MainActor final class Coordinator: NSObject {
        var parent: MinuteSlider
        init(_ parent: MinuteSlider) { self.parent = parent }
        @objc func changed(_ slider: NSSlider) { parent.value = slider.integerValue }
    }
}

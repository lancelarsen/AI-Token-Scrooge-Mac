import SwiftUI

struct AccountSettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let accountID: String
    @State private var newColor = Color(hex: "#B5A0F4")
    @State private var showColor = false
    @State private var confirmRemove = false
    private var account: ProviderAccount? { store.state.accounts.first { $0.id == accountID } }
    private var lineColors: [String] {
        var seen = Set<String>()
        return (Theme.palette + store.state.settings.customColors).filter { seen.insert($0.uppercased()).inserted }
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack { Text("Account Settings").font(.system(size: 26, weight: .semibold)).foregroundStyle(Theme.accent); Spacer(); Button("Close") { dismiss() }.buttonStyle(ScroogeButtonStyle()) }.padding(24)
            ScrollView {
                if let account {
                    VStack(spacing: 12) {
                        SettingsCard(title: "Account", symbol: "person.crop.circle") {
                            TextField("Account Name", text: Binding(get: { account.nickname }, set: { value in update { $0.nickname = value } })).textFieldStyle(.roundedBorder)
                            Text("Line Color")
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 36, maximum: 40))], alignment: .leading) {
                                ForEach(lineColors, id: \.self) { hex in
                                    Button { update { $0.lineColor = hex } } label: {
                                        ZStack { RoundedRectangle(cornerRadius: 5).fill(Color(hex: hex)); if account.lineColor == hex { Image(systemName: "checkmark").foregroundStyle(.black) } }.frame(width: 32, height: 32)
                                    }.buttonStyle(.plain).accessibilityLabel("Line Color \(hex)")
                                }
                                Button { showColor = true } label: { Image(systemName: "plus").frame(width: 32, height: 32).background(Theme.control).clipShape(RoundedRectangle(cornerRadius: 5)) }.buttonStyle(.plain).help("Add Custom Color")
                                    .popover(isPresented: $showColor) {
                                        VStack { ColorPicker("Custom Line Color", selection: $newColor, supportsOpacity: false); Button("Add Color") {
                                            let hex = newColor.hex; store.edit { state in
                                                if !state.settings.customColors.contains(hex) { state.settings.customColors.append(hex) }
                                                if let i = state.accounts.firstIndex(where: { $0.id == accountID }) { state.accounts[i].lineColor = hex }
                                            }; showColor = false
                                        } }.padding(20)
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
                        if let reserve = store.state.snapshots[accountID]?.reserve {
                            SettingsCard(title: "Available Resets", symbol: "hourglass") {
                                Text("\(reserve.availableCount.map(String.init) ?? "Unknown") Available").font(.title2)
                                ForEach(reserve.credits ?? []) { credit in Text("Expires \(Format.date(credit.expiresAt, zone: store.state.settings.zone))") }
                                if reserve.hasPartialDetails { Text("Some reset details are not supplied by the provider.").foregroundStyle(Theme.secondary) }
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
        .confirmationDialog("Remove This Account?", isPresented: $confirmRemove) {
            Button("Remove Account", role: .destructive) { Task { await store.removeAccount(accountID); dismiss() } }
        } message: { Text("This removes its local history and Scrooge-owned connection. Your other apps stay signed in.") }
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

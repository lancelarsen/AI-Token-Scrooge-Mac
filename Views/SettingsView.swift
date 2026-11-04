import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var updater = AppUpdater.shared
    @State private var pendingRetention: Int?
    var body: some View {
        VStack(spacing: 0) {
            HStack { ActionLabel(title: "Settings", symbol: "gearshape").font(.system(size: 26, weight: .semibold)); Spacer(); Button("Close") { dismiss() }.buttonStyle(ScroogeButtonStyle()) }.padding(.horizontal, 20).padding(.vertical, 12)
            ScrollView {
                VStack(spacing: 12) {
                    if store.isDemo { Text("Demo changes stay in this preview. Notification tests use macOS.").font(.system(size: 13)).foregroundStyle(Theme.accent).frame(maxWidth: .infinity, alignment: .leading) }
                    SettingsCard(title: "App Updates", symbol: "arrow.down.circle") {
                        Text(AppUpdater.displayVersion).font(.headline)
                        Toggle("Automatically Check for Updates", isOn: $updater.automaticChecks)
                        Text("Checks every eight hours. Downloads and installation require your choice.").font(.caption).foregroundStyle(Theme.secondary)
                        HStack {
                            Button("Check Now") { updater.checkNow() }.buttonStyle(ScroogeButtonStyle()).disabled(!updater.canCheck)
                            if let checked = updater.lastChecked { Text("Last checked \(checked.formatted(date: .abbreviated, time: .shortened))").font(.caption).foregroundStyle(Theme.secondary) }
                        }
                    }
                    SettingsCard(title: "Time Zone", symbol: "globe") {
                        Menu {
                            Picker("Time Zone", selection: Binding(get: { store.state.settings.zone.identifier }, set: { zone in store.edit { $0.settings.timeZoneID = zone } })) {
                                ForEach(Array(Set(TimeZone.knownTimeZoneIdentifiers + [store.state.settings.zone.identifier])).sorted(), id: \.self) { Text($0.replacingOccurrences(of: "_", with: " ")).tag($0) }
                            }.pickerStyle(.inline)
                        } label: {
                            HStack {
                                Text(store.state.settings.zone.identifier.replacingOccurrences(of: "_", with: " "))
                                Spacer()
                                Image(systemName: "chevron.down").foregroundStyle(Theme.secondary)
                            }.font(.system(size: 13)).padding(.horizontal, 12).frame(height: 32)
                                .background(Theme.control, in: RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border))
                        }.menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden)
                            .accessibilityLabel("Time Zone").accessibilityValue(store.state.settings.zone.identifier)
                    }
                    SettingsCard(title: "History and Alerts", symbol: "clock.arrow.circlepath", help: "Choose how long to keep recorded usage and alerts. Increasing retention cannot recover deleted records.") {
                        Picker("Keep History and Alerts", selection: Binding(get: { store.state.settings.historyRetentionDays }, set: { days in
                            if days < store.state.settings.historyRetentionDays { pendingRetention = days }
                            else { store.edit { $0.settings.historyRetentionDays = days } }
                        })) { ForEach(Array(Set([7,30,60,90,180,365,store.state.settings.historyRetentionDays])).sorted(), id: \.self) { Text("\($0) Days").tag($0) } }
                    }
                    SettingsCard(title: "Notifications", symbol: "desktopcomputer") {
                        Text("Choose how Scrooge gets your attention.").font(.system(size: 13)).foregroundStyle(Theme.secondary)
                        settingsSwitch("Popup Notifications", isOn: binding(\.notifications))
                        settingsSwitch("Alert on Icon", isOn: binding(\.alertOnIcon))
                    }
                    SettingsCard(title: "Sounds", symbol: "speaker.wave.2") {
                        settingsSwitch("Notification Sounds", isOn: binding(\.sound))
                        HStack { Text("Volume: \(Int(store.state.settings.soundVolume))%").frame(width: 112, alignment: .leading); Slider(value: binding(\.soundVolume), in: 0...100, step: 1).accessibilityLabel("Sound Volume") }
                        Picker("Sound Theme", selection: binding(\.soundTheme)) { Text("Duck Sounds").tag("Ducks"); Text("Classic Chimes").tag("Classic") }.pickerStyle(.radioGroup).labelsHidden()
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
                            ForEach(["Alarm", "Snooze", "Dismiss", "Show Info"], id: \.self) { cue in
                                Button {
                                    let sound = cue == "Alarm" ? "alert" : cue == "Show Info" ? "info" : cue.lowercased()
                                    SoundPlayer.shared.play(settings: store.state.settings, cue: sound, preview: true)
                                } label: {
                                    Label("Preview \(cue)", systemImage: "play").frame(maxWidth: .infinity, alignment: .leading)
                                }.buttonStyle(ScroogeButtonStyle())
                            }
                        }
                    }
                    SettingsCard(title: "Quiet Hours", symbol: "moon", help: "Quiet notification delivery during this time range while monitoring continues.") {
                        Toggle("Quiet Hours", isOn: binding(\.quietHours))
                        QuietHoursControl(start: binding(\.quietStartHour), end: binding(\.quietEndHour))
                            .disabled(!store.state.settings.quietHours)
                            .opacity(store.state.settings.quietHours ? 1 : 0.5)
                    }
                    SettingsCard(title: "Default Alert Levels", symbol: "slider.horizontal.3") {
                        ForEach(ReminderSeverity.allCases, id: \.self) { level in
                            ThresholdSetting(level: level, thresholds: store.state.settings.thresholds) { thresholds in store.edit { $0.settings.thresholds = thresholds } }
                        }
                    }
                    SettingsCard(title: "Earned Reset Expiration Alerts", symbol: "hourglass") {
                        ReminderEditor(reminders: binding(\.resetExpiryReminders))
                    }
                    SettingsCard(title: "Quota Refresh Alerts", symbol: "arrow.clockwise") {
                        ReminderEditor(reminders: binding(\.quotaRefreshReminders))
                    }
                    SettingsCard(title: "App Behavior", symbol: "macwindow") {
                        Toggle("Launch at Sign-In", isOn: Binding(get: { store.state.settings.launchAtSignIn }, set: { store.setLaunchAtSignIn($0) }))
                        if let message = store.loginItemMessage { Text(message).font(.caption).foregroundStyle(Theme.secondary) }
                        if store.loginItemNeedsApproval { Button("Open Login Items") { LoginItemService.openSettings() }.buttonStyle(ScroogeButtonStyle()) }
                        Toggle("Keep Monitoring After Closing", isOn: binding(\.closeToMenuBar))
                        Toggle("Privacy Mode", isOn: binding(\.privacy))
                        Button("Alert History") { store.showAlertHistory = true }.buttonStyle(ScroogeButtonStyle())
                        Button("Send Test Notification") { dismiss(); Task { await store.sendTestNotification() } }.buttonStyle(ScroogeButtonStyle())
                    }
                }.frame(maxWidth: 960).padding(.horizontal, 36).padding(.top, 12).padding(.bottom, 20).frame(maxWidth: .infinity)
            }
            if let error = store.errorMessage { Text(error).foregroundStyle(Theme.amber).padding() }
        }.frame(minWidth: 700, idealWidth: 1000, minHeight: 600, idealHeight: 800).background(Theme.background).preferredColorScheme(.dark).tint(Theme.accent)
        .onAppear { store.refreshLoginItemStatus() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { store.refreshLoginItemStatus() } }
        .sheet(isPresented: Binding(get: { pendingRetention != nil }, set: { if !$0 { pendingRetention = nil } })) {
            ConfirmationDetailsDialog(title: "Remove Older History?",
                message: "Records older than the selected period will be removed. Increasing the period later cannot restore them.",
                actionTitle: "Keep \(pendingRetention ?? 90) Days", cancel: { pendingRetention = nil }) {
                    if let days = pendingRetention { store.edit { $0.settings.historyRetentionDays = days }; pendingRetention = nil }
                }
        }
        .sheet(isPresented: Binding(get: { store.showAlertHistory }, set: { store.showAlertHistory = $0 })) { AlertHistoryView().environment(store) }
    }
    private func settingsSwitch(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title).font(.system(size: 13))
            Spacer()
            Toggle(title, isOn: isOn).labelsHidden().toggleStyle(.switch).controlSize(.small)
        }.frame(minHeight: 36)
    }
    private func binding<T>(_ path: WritableKeyPath<RadarSettings,T>) -> Binding<T> {
        Binding(get: { store.state.settings[keyPath: path] }, set: { value in store.edit { $0.settings[keyPath: path] = value } })
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    let symbol: String
    var help: String? = nil
    @ViewBuilder var content: Content
    var body: some View {
        ScroogeCard(inset: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(title, systemImage: symbol).font(.system(size: 21, weight: .semibold)).foregroundStyle(Theme.accent)
                    if let help { Image(systemName: "info.circle").foregroundStyle(Theme.secondary).help(help) }
                }
                content
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
struct ThresholdSetting: View {
    let level: ReminderSeverity
    let thresholds: AlertThresholds
    let change: (AlertThresholds) -> Void
    private var value: Decimal { switch level { case .info: thresholds.info; case .warning: thresholds.warning; case .critical: thresholds.critical } }
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(level.rawValue) @ \(Format.percent(value)) Left")
            Slider(value: Binding(get: { NSDecimalNumber(decimal: value).doubleValue }, set: { number in var next = thresholds; next.move(level, to: Decimal(number)); change(next) }), in: 0...100, step: 1)
                .accessibilityLabel("\(level.rawValue) Alert Threshold")
        }
    }
}
struct ReminderEditor: View {
    @Binding var reminders: [TimedReminder]
    var body: some View {
        VStack(spacing: 8) {
            ForEach(reminders) { reminder in
                HStack {
                    Stepper(value: Binding(get: { reminder.amount }, set: { value in update(reminder.id) { $0.amount = value } }), in: 1...365) { Text("\(reminder.amount)").frame(width: 36) }
                    Picker("Unit", selection: Binding(get: { reminder.unit }, set: { value in update(reminder.id) { $0.unit = value } })) { Text("Hours").tag("Hours"); Text("Days").tag("Days") }.labelsHidden()
                    Text("Before").foregroundStyle(Theme.secondary)
                    Picker("Severity", selection: Binding(get: { reminder.severity }, set: { value in update(reminder.id) { $0.severity = value } })) {
                        ForEach(ReminderSeverity.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.labelsHidden()
                    Button { reminders.removeAll { $0.id == reminder.id } } label: { Image(systemName: "trash") }.help("Remove Reminder")
                }
            }
            Button { reminders.append(TimedReminder(amount: 1, unit: "Hours", severity: .info)) } label: { ActionLabel(title: "Add Reminder", symbol: "plus") }.buttonStyle(ScroogeButtonStyle())
        }
    }
    private func update(_ id: String, change: (inout TimedReminder) -> Void) {
        var copy = reminders; if let index = copy.firstIndex(where: { $0.id == id }) { change(&copy[index]); reminders = copy }
    }
}
struct QuietHoursControl: View {
    @FocusState private var focusedBoundary: String?
    @Binding var start: Int
    @Binding var end: Int
    var body: some View {
        VStack {
            HStack { Text("\(hour(start)) – \(hour(end))"); Spacer() }.font(.system(size: 16)).foregroundStyle(Theme.secondary)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.border).frame(height: 5)
                    ForEach(0..<24) { h in Rectangle().fill(Theme.secondary.opacity(0.4)).frame(width: 1, height: h % 6 == 0 ? 15 : 7).offset(x: CGFloat(h) / 23 * geometry.size.width) }
                    handle(value: $start, width: geometry.size.width, label: "Quiet Hours Start")
                    handle(value: $end, width: geometry.size.width, label: "Quiet Hours End")
                }.frame(height: 30).coordinateSpace(name: "quietHours")
            }.frame(height: 32).padding(.horizontal, 10)
            HStack { Text("Midnight"); Spacer(); Text("Noon"); Spacer(); Text("11 PM") }.font(.system(size: 16)).foregroundStyle(Theme.secondary)
        }
    }
    private func handle(value: Binding<Int>, width: Double, label: String) -> some View {
        Circle().fill(Theme.accent).frame(width: 18, height: 18)
            .overlay(Circle().stroke(.white, lineWidth: focusedBoundary == label ? 2 : 0).padding(-4))
            .offset(x: Double(value.wrappedValue) / 23 * width - 9)
            .focusable().focused($focusedBoundary, equals: label).focusEffectDisabled()
            .onKeyPress(keys: [.leftArrow, .rightArrow, .upArrow, .downArrow]) { press in
                let change = press.key == .leftArrow || press.key == .downArrow ? -1 : 1
                value.wrappedValue = (value.wrappedValue + change + 24) % 24
                return .handled
            }
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("quietHours")).onChanged { event in
                focusedBoundary = label
                value.wrappedValue = min(23, max(0, Int((event.location.x / width * 23).rounded())))
            }).accessibilityLabel(label).accessibilityValue(hour(value.wrappedValue))
            .accessibilityAdjustableAction { direction in value.wrappedValue = (value.wrappedValue + (direction == .increment ? 1 : 23)) % 24 }
    }
    private func hour(_ value: Int) -> String { value == 0 ? "Midnight" : value == 12 ? "Noon" : "\(value % 12) \(value < 12 ? "AM" : "PM")" }
}

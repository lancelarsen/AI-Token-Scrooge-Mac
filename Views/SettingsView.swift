import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var updater = AppUpdater.shared
    @State private var pendingRetention: Int?
    @State private var panelSize = CGSize(width: 1000, height: 800)
    var body: some View {
        VStack(spacing: 0) {
            HStack { ActionLabel(title: "Settings", symbol: "gearshape").font(.system(size: 26, weight: .semibold)); Spacer(); Button { dismiss() } label: { DialogActionLabel(title: "Close", symbol: "xmark") }.buttonStyle(ScroogeButtonStyle()) }.padding(.horizontal, 20).padding(.vertical, 12)
            ScrollView {
                VStack(spacing: 12) {
                    if store.isDemo { Text("Demo changes stay in this preview. Notification tests use macOS.").font(.system(size: 13)).foregroundStyle(Theme.accent).frame(maxWidth: .infinity, alignment: .leading) }
                    SettingsCard(title: "App Updates", symbol: "arrow.down.circle") {
                        Text(AppUpdater.displayVersion).font(.headline)
                        settingsSwitch("Automatically Check for Updates", isOn: $updater.automaticChecks)
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
                    SettingsCard(title: "History and Alerts", symbol: "gearshape") {
                        Text("Choose how long to keep recorded usage and alerts. Shortening this period removes older records; increasing it cannot restore deleted records.")
                            .font(.system(size: 13)).foregroundStyle(Theme.secondary)
                        Menu {
                            ForEach(Array(Set([7,30,60,90,180,365,store.state.settings.historyRetentionDays])).sorted(), id: \.self) { days in
                                Button("\(days) Days") {
                                    if days < store.state.settings.historyRetentionDays { pendingRetention = days }
                                    else { store.edit { $0.settings.historyRetentionDays = days } }
                                }
                            }
                        } label: {
                            HStack {
                                Text("\(store.state.settings.historyRetentionDays) Days")
                                Spacer()
                                Image(systemName: "chevron.down").font(.system(size: 10)).foregroundStyle(Theme.secondary)
                            }.padding(.horizontal, 12).frame(height: 32)
                                .background(Theme.control, in: RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border))
                        }.menuStyle(.borderlessButton).menuIndicator(.hidden)
                            .accessibilityLabel("Keep History and Alerts").accessibilityValue("\(store.state.settings.historyRetentionDays) Days")
                    }
                    SettingsCard(title: "Notifications", symbol: "desktopcomputer") {
                        Text("Choose how Scrooge gets your attention.").font(.system(size: 13)).foregroundStyle(Theme.secondary)
                        settingsSwitch("Popup Notifications", isOn: binding(\.notifications))
                        settingsSwitch("Alert on Icon", isOn: binding(\.alertOnIcon))
                    }
                    SettingsCard(title: "Sounds", symbol: "speaker.wave.2") {
                        settingsSwitch("Notification Sounds", isOn: binding(\.sound))
                        HStack { Text("Volume: \(Int(store.state.settings.soundVolume))%").frame(width: 112, alignment: .leading); ScroogePercentSlider(value: binding(\.soundVolume), color: Color(hex: "#A990ED")).accessibilityLabel("Sound Volume") }
                        VStack(alignment: .leading, spacing: 12) {
                            soundThemeOption("Duck Sounds", value: "Ducks")
                            soundThemeOption("Classic Chimes", value: "Classic")
                        }
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
                            ForEach(["Alarm", "Snooze", "Dismiss", "Show Info"], id: \.self) { cue in
                                Button {
                                    let sound = cue == "Alarm" ? "alert" : cue == "Show Info" ? "info" : cue.lowercased()
                                    SoundPlayer.shared.play(settings: store.state.settings, cue: sound, preview: true)
                                } label: {
                                    DialogActionLabel(title: "Preview \(cue)", symbol: "play").frame(maxWidth: .infinity, alignment: .leading)
                                }.buttonStyle(ScroogeButtonStyle())
                            }
                        }
                    }
                    SettingsCard(title: "Quiet Hours", symbol: "moon", help: "Quiet notification delivery during this time range while monitoring continues.", headerToggle: binding(\.quietHours)) {
                        Text("A little peace, right on schedule.").font(.system(size: 13)).foregroundStyle(Theme.secondary)
                        QuietHoursControl(start: binding(\.quietStartHour), end: binding(\.quietEndHour))
                            .disabled(!store.state.settings.quietHours)
                            .opacity(store.state.settings.quietHours ? 1 : 0.5)
                    }
                    SettingsCard(title: "Default Alert Levels", symbol: "slider.horizontal.3") {
                        ForEach(ReminderSeverity.allCases, id: \.self) { level in
                            ThresholdSetting(level: level, thresholds: store.state.settings.thresholds) { thresholds in store.edit { $0.settings.thresholds = thresholds } }
                        }
                    }
                    SettingsCard(title: "Earned Reset Expiration Alerts", symbol: "clock") {
                        ReminderEditor(reminders: binding(\.resetExpiryReminders))
                    }
                    SettingsCard(title: "Quota Refresh Alerts", symbol: "arrow.clockwise") {
                        ReminderEditor(reminders: binding(\.quotaRefreshReminders))
                    }
                    SettingsCard(title: "App Behavior", symbol: "gearshape") {
                        settingsSwitch("Keep Monitoring When Window Closes", isOn: binding(\.closeToMenuBar))
                        settingsSwitch("Launch at Sign-In", isOn: Binding(get: { store.state.settings.launchAtSignIn }, set: { store.setLaunchAtSignIn($0) }))
                        if let message = store.loginItemMessage { Text(message).font(.caption).foregroundStyle(Theme.secondary) }
                        if store.loginItemNeedsApproval { Button("Open Login Items") { LoginItemService.openSettings() }.buttonStyle(ScroogeButtonStyle()) }
                        settingsSwitch("Privacy Mode", isOn: binding(\.privacy))
                        Button { store.showAlertHistory = true } label: { DialogActionLabel(title: "Alert History", symbol: "clock.arrow.circlepath").frame(maxWidth: .infinity, alignment: .leading) }.buttonStyle(ScroogeButtonStyle())
                        Button { dismiss(); Task { await store.sendTestNotification() } } label: { DialogActionLabel(title: "Send Test Notification", symbol: "desktopcomputer").frame(maxWidth: .infinity, alignment: .leading) }.buttonStyle(ScroogeButtonStyle())
                    }
                }.frame(maxWidth: 960).padding(.horizontal, 36).padding(.top, 12).padding(.bottom, 20).frame(maxWidth: .infinity)
            }
            if let error = store.errorMessage { Text(error).foregroundStyle(Theme.amber).padding() }
        }.font(.system(size: 14)).frame(width: panelSize.width, height: panelSize.height).background(Theme.background).preferredColorScheme(.dark).tint(Theme.accent)
        .onAppear {
            store.refreshLoginItemStatus()
            if let parent = NSApp.keyWindow?.sheetParent {
                let size = parent.contentView?.bounds.size ?? parent.frame.size
                panelSize = CGSize(width: min(1000, max(640, size.width - 48)), height: min(800, max(400, size.height - 64)))
            }
        }
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
    private func soundThemeOption(_ title: String, value: String) -> some View {
        let selected = store.state.settings.soundTheme == value
        return Button { store.edit { $0.settings.soundTheme = value } } label: {
            HStack(spacing: 8) {
                Circle().stroke(selected ? Theme.accent : Theme.secondary, lineWidth: selected ? 5 : 1)
                    .frame(width: 16, height: 16).padding(2)
                Text(title).font(.system(size: 14)).foregroundStyle(.white)
            }.contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel(title).accessibilityAddTraits(selected ? .isSelected : [])
    }
    private func settingsSwitch(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .font(.system(size: 14))
            .toggleStyle(ScroogeSwitchStyle())
            .frame(minHeight: 36)
    }
    private func binding<T>(_ path: WritableKeyPath<RadarSettings,T>) -> Binding<T> {
        Binding(get: { store.state.settings[keyPath: path] }, set: { value in store.edit { $0.settings[keyPath: path] = value } })
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    let symbol: String
    var help: String? = nil
    var headerToggle: Binding<Bool>? = nil
    @ViewBuilder var content: Content
    var body: some View {
        ScroogeCard(inset: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    if let help { Image(systemName: "info.circle").font(.system(size: 14)).foregroundStyle(Theme.accent).help(help) }
                    Label(title, systemImage: symbol).font(.system(size: 21, weight: .semibold)).foregroundStyle(Theme.accent)
                    if let headerToggle {
                        Spacer()
                        Toggle(title, isOn: headerToggle).toggleStyle(ScroogeSwitchStyle(showsLabel: false)).frame(width: 40, height: 20).accessibilityLabel(title)
                    }
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
    private var color: Color {
        switch level {
        case .info: Color(hex: "#58A6FF")
        case .warning: Color(hex: "#F2C94C")
        case .critical: Color(hex: "#F05B69")
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(level.rawValue) Alert @ \(Format.percent(value)) Left").foregroundStyle(color)
            ScroogePercentSlider(value: Binding(get: { NSDecimalNumber(decimal: value).doubleValue }, set: { number in var next = thresholds; next.move(level, to: Decimal(number)); change(next) }), color: color)
                .accessibilityLabel("\(level.rawValue) Alert Threshold")
        }
    }
}
struct ReminderEditor: View {
    @Binding var reminders: [TimedReminder]
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(reminders) { reminder in
                HStack(spacing: 8) {
                    Menu {
                        ForEach(ReminderSeverity.allCases, id: \.self) { level in
                            Button(level.rawValue) { update(reminder.id) { $0.severity = level } }
                        }
                    } label: {
                        menuLabel(reminder.severity.rawValue, color: severityColor(reminder.severity))
                    }.menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden).frame(maxWidth: .infinity).accessibilityLabel("Severity")
                    TextField("Amount", value: Binding(get: { reminder.amount }, set: { value in update(reminder.id) { $0.amount = min(365, max(1, value)) } }), format: .number)
                        .textFieldStyle(.plain).padding(.horizontal, 12).frame(width: 80, height: 44)
                        .background(Theme.control, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border))
                        .accessibilityLabel("Reminder Amount")
                    Menu {
                        ForEach(["Hours", "Days"], id: \.self) { unit in
                            Button(unit) { update(reminder.id) { $0.unit = unit } }
                        }
                    } label: { menuLabel(reminder.unit) }
                        .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden).frame(maxWidth: .infinity).accessibilityLabel("Unit")
                    Button { reminders.removeAll { $0.id == reminder.id } } label: {
                        Image(systemName: "trash").foregroundStyle(Theme.accent).frame(width: 44, height: 44)
                            .background(Theme.control, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border))
                    }.buttonStyle(.plain).help("Remove Reminder").accessibilityLabel("Remove Reminder")
                }
            }
            Button { reminders.append(TimedReminder(amount: 1, unit: "Hours", severity: .info)) } label: { ActionLabel(title: "Add Reminder", symbol: "plus") }.buttonStyle(ScroogeButtonStyle())
        }
    }
    private func menuLabel(_ title: String, color: Color = .white) -> some View {
        HStack {
            Text(title).foregroundStyle(color)
            Spacer()
            Image(systemName: "chevron.down").font(.system(size: 10)).foregroundStyle(Theme.secondary)
        }.padding(.horizontal, 12).frame(maxWidth: .infinity).frame(height: 44)
            .background(Theme.control, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border))
    }
    private func severityColor(_ level: ReminderSeverity) -> Color {
        switch level {
        case .info: Color(hex: "#58A6FF")
        case .warning: Color(hex: "#F2C94C")
        case .critical: Color(hex: "#F05B69")
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
    @State private var trackWidth: CGFloat = 800
    private func position(_ hour: Int, isEnd: Bool = false) -> Double {
        isEnd && hour == 12 ? 1 : Double((hour + 12) % 24) / 24
    }
    private var closeLabels: Bool { abs(position(start) - position(end, isEnd: true)) * max(0, trackWidth - 64) < 106 }
    private var summary: String {
        let duration = (end - start + 24) % 24
        return duration == 0 ? "Choose different start and end times to set a quiet period." :
            "\(hour(start)) – \(hour(end)) · \(duration) hours\(end < start ? " · Overnight" : "")"
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geometry in
                let span = max(0, geometry.size.width - 64)
                let a = 32 + position(start) * span
                let b = 32 + position(end, isEnd: true) * span
                let y: CGFloat = closeLabels ? 66 : 44
                ZStack(alignment: .topLeading) {
                    Canvas { context, size in
                        func line(_ from: CGFloat, _ to: CGFloat, _ color: Color) {
                            var path = Path(); path.move(to: CGPoint(x: from, y: y)); path.addLine(to: CGPoint(x: to, y: y))
                            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        }
                        line(32, size.width - 32, Color(hex: "#41434F"))
                        if start != end {
                            if a < b { line(a, b, Color(hex: "#A990ED")) }
                            else { line(a, size.width - 32, Color(hex: "#A990ED")); line(32, b, Color(hex: "#A990ED")) }
                        }
                    }
                    ForEach(0..<5) { index in
                        Text(["12 PM", "6 PM", "12 AM", "6 AM", "12 PM"][index])
                            .font(.system(size: 16)).foregroundStyle(Theme.accent)
                            .frame(width: 64, height: 24).position(x: 32 + span * Double(index) / 4, y: y + 34)
                    }
                    handle(value: $start, x: a, y: y, width: geometry.size.width, label: "Quiet Hours Start", labelY: 16)
                    handle(value: $end, x: b, y: y, width: geometry.size.width, label: "Quiet Hours End", labelY: closeLabels ? 38 : 16)
                }.coordinateSpace(name: "quietHours")
            }
            .frame(height: closeLabels ? 116 : 94)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { trackWidth = $0 }
            Text(summary).font(.system(size: 16)).foregroundStyle(Theme.accent)
        }
    }
    private func handle(value: Binding<Int>, x: CGFloat, y: CGFloat, width: CGFloat, label: String, labelY: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Text(hour(value.wrappedValue)).font(.system(size: 16)).foregroundStyle(.white)
                .frame(width: 106, height: 32).position(x: min(max(x, 53), width - 53), y: labelY)
            Circle().fill(Theme.accent).overlay(Circle().stroke(Color(hex: "#7160B4"), lineWidth: 3))
                .frame(width: 24, height: 24)
                .overlay(Circle().stroke(.white, lineWidth: focusedBoundary == label ? 2 : 0).padding(-4))
                .position(x: x, y: y)
                .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("quietHours")).onChanged { event in
                    focusedBoundary = label
                    let fraction = min(1, max(0, (event.location.x - 32) / max(1, width - 64)))
                    value.wrappedValue = (Int((fraction * 24).rounded()) + 12) % 24
                })
        }
        .focusable().focused($focusedBoundary, equals: label).focusEffectDisabled()
        .onKeyPress(keys: [.leftArrow, .rightArrow, .upArrow, .downArrow]) { press in
            let change = press.key == .leftArrow || press.key == .downArrow ? -1 : 1
            value.wrappedValue = (value.wrappedValue + change + 24) % 24
            return .handled
        }
        .accessibilityElement(children: .ignore).accessibilityLabel(label).accessibilityValue(hour(value.wrappedValue))
        .accessibilityAdjustableAction { direction in value.wrappedValue = (value.wrappedValue + (direction == .increment ? 1 : 23)) % 24 }
    }
    private func hour(_ value: Int) -> String { "\(value % 12 == 0 ? 12 : value % 12) \(value < 12 ? "AM" : "PM")" }
}

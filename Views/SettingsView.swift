import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var updater = AppUpdater.shared
    @State private var isClosing = false
    @State private var invalidReminderSections: Set<String> = []
    @State private var showAlertHistory = false
    @State private var pendingRetention: Int?
    @State private var demoAutomaticChecks = true
    @State private var soundPreviewStatus: String?
    @Environment(\.dashboardHostSize) private var hostSize
    private func setReminderValidation(_ section: String, invalid: Bool) {
        if invalid { invalidReminderSections.insert(section) }
        else { invalidReminderSections.remove(section) }
    }
    private var panelSize: CGSize {
        guard let hostSize else { return CGSize(width: 1000, height: 800) }
        return CGSize(width: min(1000, max(640, hostSize.width - 48)),
                      height: min(800, max(400, hostSize.height - 64)))
    }
    private var statusMessage: String? {
        invalidReminderSections.isEmpty ? (store.settingsSaveError ?? store.errorMessage) : "Enter a Positive Whole Number for Each Reminder"
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack { HStack(spacing: 10) { ActionIcon(symbol: "gearshape", size: 26).frame(width: 29).environment(\.actionForeground, Theme.accent); Text("Settings").font(.reference(size: 26, weight: .semibold)).referenceFallbackLineMetrics(size: 26) }; Spacer(); SettingsCloseButton(isClosing: $isClosing, canClose: invalidReminderSections.isEmpty) }.padding(.horizontal, 20).padding(.vertical, 12)
            SettingsScrollView {
                VStack(spacing: 12) {
                    if store.isDemo { Text("Demo changes stay in this preview. Notification test uses macOS.").font(.reference(size: 14)).foregroundStyle(Theme.actionAccent).frame(maxWidth: .infinity, alignment: .leading) }
                    SettingsCard(title: "App Updates", symbol: "gearshape") {
                        Text(AppUpdater.versionLabel).font(.reference(size: 16)).referenceClassicLineMetrics(size: 16)
                        settingsSwitch("Check for Newer Versions", isOn: Binding(
                            get: { store.isDemo ? demoAutomaticChecks : updater.automaticChecks },
                            set: { if store.isDemo { demoAutomaticChecks = $0 } else { updater.automaticChecks = $0 } }
                        )).disabled(!AppUpdater.supportsUpdates)
                        Text(!AppUpdater.supportsUpdates ? "Updates are disabled for local development builds. Rebuild to use the latest code." : store.isDemo ? "Update Checks Are Paused in Demo" : "Downloads and installation require your choice.")
                            .font(.reference(size: 13)).referenceClassicLineMetrics(size: 13).foregroundStyle(Color(hex: "#BEC1D2"))
                        if AppUpdater.supportsUpdates {
                            Text(updater.lastChecked.map { "Last Checked: \(Format.snapshotDate($0, zone: store.state.settings.zone))" }
                                 ?? "Checks for updates every 8 hours while Scrooge is running.")
                                .font(.reference(size: 12)).foregroundStyle(Color(hex: "#A5A8BA"))
                        }
                        HStack(spacing: 8) {
                            Button { updater.checkNow() } label: {
                                ActionLabel(title: "Check Now", symbol: "arrow.clockwise")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }.buttonStyle(ScroogeButtonStyle()).disabled(store.isDemo || !updater.canCheck)
                            Color.clear.frame(maxWidth: .infinity).accessibilityHidden(true)
                        }.fixedSize(horizontal: false, vertical: true)
                    }
                    SettingsCard(title: "Time Zone", symbol: "globe") {
                        Menu {
                            Picker("Time Zone", selection: Binding(get: { store.state.settings.zone.identifier }, set: { zone in store.edit { $0.settings.timeZoneID = zone } })) {
                                ForEach(Format.sortedTimeZones(identifiers: TimeZone.knownTimeZoneIdentifiers + [store.state.settings.zone.identifier]), id: \.identifier) { zone in Text(Format.timeZoneName(zone)).tag(zone.identifier) }
                            }.pickerStyle(.inline)
                        } label: {
                            HStack {
                                Text(Format.timeZoneName(store.state.settings.zone)).font(ReferenceTypography.nativeTextFont())
                                Spacer()
                                ReferenceDropdownChevron().foregroundStyle(Theme.secondary)
                            }.font(.reference(size: 13)).padding(.horizontal, 12).frame(height: 32)
                                .background(Theme.control, in: RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border))
                        }.menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden)
                            .accessibilityLabel("Time Zone").accessibilityValue(Format.timeZoneName(store.state.settings.zone))
                    }
                    SettingsCard(title: "History and Alerts", symbol: "gearshape", description: "Choose how long to keep recorded usage and alerts. Shortening this period removes older records; increasing it cannot restore deleted records.") {
                        Menu {
                            ForEach(Array(Set([7,30,60,90,180,365,store.state.settings.historyRetentionDays])).sorted(), id: \.self) { days in
                                Button("\(days) Days") {
                                    if days < store.state.settings.historyRetentionDays { pendingRetention = days }
                                    else { store.edit { $0.settings.historyRetentionDays = days } }
                                }
                            }
                        } label: {
                            HStack {
                                Text("\(store.state.settings.historyRetentionDays) Days").font(ReferenceTypography.nativeTextFont())
                                Spacer()
                                ReferenceDropdownChevron().foregroundStyle(Theme.secondary)
                            }.padding(.horizontal, 12).frame(height: 32)
                                .background(Theme.control, in: RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border))
                        }.menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden)
                            .accessibilityLabel("Keep History and Alerts").accessibilityValue("\(store.state.settings.historyRetentionDays) Days")
                    }
                    SettingsCard(title: "Notifications", symbol: "desktopcomputer", description: "Choose how Scrooge gets your attention.") {
                        settingsSwitch("Popup Notifications", isOn: binding(\.notifications))
                        settingsSwitch("Alert on Icon", isOn: binding(\.alertOnIcon))
                    }
                    SettingsCard(title: "Sounds", symbol: "speaker.wave.2") {
                        settingsSwitch("Notification Sounds", isOn: binding(\.sound))
                        HStack(spacing: 12) { Text("Volume: \(Int(store.state.settings.soundVolume.rounded(.toNearestOrEven)))%").foregroundStyle(Theme.dialogText).frame(width: 112, alignment: .leading); ScroogePercentSlider(value: binding(\.soundVolume), color: Color(hex: "#A990ED"), thumbColor: Theme.accent, roundsValue: false).accessibilityLabel("Sound Volume") }
                        VStack(alignment: .leading, spacing: 0) {
                            soundThemeOption("Duck Sounds", value: "Ducks")
                            soundThemeOption("Classic Chimes", value: "Classic")
                        }
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
                            ForEach(["Alarm", "Snooze", "Dismiss", "Show Info"], id: \.self) { cue in
                                Button {
                                    let sound = cue == "Alarm" ? "alert" : cue == "Show Info" ? "info" : cue.lowercased()
                                    soundPreviewStatus = SoundPlayer.shared.play(settings: store.state.settings, cue: sound, preview: true)
                                } label: {
                                    DialogActionLabel(title: "Preview \(cue)").frame(maxWidth: .infinity, alignment: .leading)
                                }.buttonStyle(ScroogeButtonStyle())
                            }
                        }
                        Text(soundPreviewStatus ?? "").font(.reference(size: 12)).foregroundStyle(Theme.amber)
                            .frame(minHeight: 16, alignment: .leading)
                            .accessibilityHidden(soundPreviewStatus == nil)
                    }
                    SettingsCard(title: "Quiet Hours", symbol: "moon", headerToggle: binding(\.quietHours), description: "A little peace, right on schedule.") {
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
                        ReminderEditor(reminders: binding(\.resetExpiryReminders), onValidationChange: { setReminderValidation("expiry", invalid: $0) })
                    }
                    SettingsCard(title: "Quota Refresh Alerts", symbol: "arrow.clockwise") {
                        ReminderEditor(reminders: binding(\.quotaRefreshReminders), onValidationChange: { setReminderValidation("refresh", invalid: $0) })
                    }
                    SettingsCard(title: "App Behavior", symbol: "gearshape") {
                        settingsSwitch("Keep Monitoring When Window Closes", isOn: binding(\.closeToMenuBar))
                        settingsSwitch("Launch at Sign-In", isOn: Binding(get: { store.state.settings.launchAtSignIn }, set: { store.setLaunchAtSignIn($0) }))
                            .disabled(store.isDemo)
                        if let message = store.loginItemMessage { Text(message).font(.reference(size: 12)).foregroundStyle(Theme.secondary) }
                        if store.loginItemNeedsApproval { Button("Open Login Items") { LoginItemService.openSettings() }.buttonStyle(ScroogeButtonStyle()) }
                        Button { showAlertHistory = true } label: { DialogActionLabel(title: "Alert History").frame(maxWidth: .infinity, alignment: .leading) }.buttonStyle(ScroogeButtonStyle())
                        Button {
                            guard !isClosing, invalidReminderSections.isEmpty else { return }
                            isClosing = true
                            Task {
                                if await store.finishSettingsEdits() {
                                    dismiss()
                                    await store.sendTestNotification()
                                }
                                isClosing = false
                            }
                        } label: { DialogActionLabel(title: "Send Test Notification").frame(maxWidth: .infinity, alignment: .leading) }.buttonStyle(ScroogeButtonStyle())
                    }
                }.padding(.horizontal, 16).padding(.vertical, 12).frame(width: min(960, panelSize.width - 2 - 24)).frame(maxWidth: .infinity)
            }
            .disabled(isClosing)
            // The final Windows Grid row retains its 19-point empty Label.
            Text(statusMessage ?? "").foregroundStyle(Theme.amber)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, minHeight: 19, alignment: .trailing).padding(.horizontal, 24)
                .accessibilityIdentifier("settingsSaveStatus")
                .accessibilityHidden(statusMessage == nil)
        }.font(.reference(size: 14)).foregroundStyle(Theme.primaryText).referencePanelFrame(size: panelSize).preferredColorScheme(.dark).tint(Theme.accent)
        .interactiveDismissDisabled()
        .onAppear {
            store.refreshLoginItemStatus()
            demoAutomaticChecks = updater.automaticChecks

        }
        .onChange(of: scenePhase) { _, phase in if phase == .active { store.refreshLoginItemStatus() } }
        .sheet(isPresented: Binding(get: { pendingRetention != nil }, set: { if !$0 { pendingRetention = nil } })) {
            ConfirmationDetailsDialog(title: "Remove Older History?",
                message: "Records older than the selected period will be removed. Increasing the period later cannot restore them.",
                actionTitle: "Keep \(pendingRetention ?? 90) Days", cancel: { pendingRetention = nil }) {
                    if let days = pendingRetention { store.edit { $0.settings.historyRetentionDays = days }; pendingRetention = nil }
                }
        }
        .sheet(isPresented: $showAlertHistory) { AlertHistoryView().environment(store) }
    }
    private func soundThemeOption(_ title: String, value: String) -> some View {
        let selected = store.state.settings.soundTheme == value
        return Button { store.edit { $0.settings.soundTheme = value } } label: {
            HStack(spacing: 8) {
                Circle().strokeBorder(selected ? Color(hex: "#A990ED") : Theme.secondary, lineWidth: selected ? 5 : 1)
                    .frame(width: 20, height: 20)
                Text(title).font(ReferenceTypography.nativeTextFont()).foregroundStyle(Theme.primaryText)
            }.frame(minHeight: 32).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel(title).accessibilityAddTraits(selected ? .isSelected : [])
    }
    private func settingsSwitch(_ title: String, isOn: Binding<Bool>) -> some View {
        // The Windows native Switch measures 40 high despite its row's 36-point minimum.
        Toggle(title, isOn: isOn)
            .font(.reference(size: 14))
            .toggleStyle(ScroogeSwitchStyle())
            .frame(minHeight: 40)
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
    var description: String? = nil
    @ViewBuilder var content: Content
    var body: some View {
        // WinUI Border reserves its one-point stroke before the 16-point content padding.
        ScroogeCard(inset: 17) {
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        if let text = help ?? SettingsHelpCopy.values[title] { SettingsInfoIcon(text: text) }
                        HStack(spacing: 10) {
                            ActionIcon(symbol: symbol, size: 21).frame(width: 24).environment(\.actionForeground, Theme.accent)
                            Text(title).font(.reference(size: 21, weight: .semibold)).referenceFallbackLineMetrics(size: 21)
                        }.foregroundStyle(Theme.accent)
                        if let headerToggle {
                            Spacer()
                            Toggle(title, isOn: headerToggle).toggleStyle(ScroogeSwitchStyle(showsLabel: false, onColor: Color(hex: "#8170CF"))).frame(width: 40, height: 40).accessibilityLabel(title)
                        }
                    }
                    if let description {
                        Text(description).font(.reference(size: 13)).referenceClassicLineMetrics(size: 13).foregroundStyle(Color(hex: "#A5A8BA"))
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
    var onValidationChange: (Bool) -> Void = { _ in }
    @State private var amountDrafts: [String: String] = [:]
    private var amountError: Bool {
        reminders.contains { reminder in
            guard let draft = amountDrafts[reminder.id] else { return false }
            return Int32(draft.trimmingCharacters(in: .whitespacesAndNewlines)).map { $0 <= 0 } ?? true
        }
    }
    private var orderedReminders: [TimedReminder] {
        reminders.enumerated().sorted { left, right in
            left.element.hours == right.element.hours
                ? left.offset < right.offset : left.element.hours > right.element.hours
        }.map(\.element)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(orderedReminders) { reminder in
                    HStack(spacing: 8) {
                        Menu {
                            ForEach(ReminderSeverity.allCases, id: \.self) { level in
                                Button(level.rawValue) { update(reminder.id) { $0.severity = level } }
                            }
                        } label: {
                            menuLabel(reminder.severity.rawValue, color: severityColor(reminder.severity))
                        }.menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden).frame(maxWidth: .infinity).accessibilityLabel("Reminder Severity").accessibilityValue(reminder.severity.rawValue)
                        TextField("Amount", text: Binding(get: { amountDrafts[reminder.id] ?? String(reminder.amount) }, set: { text in
                            amountDrafts[reminder.id] = text
                            update(reminder.id) { _ in }
                        }))
                            .textFieldStyle(.plain).font(ReferenceTypography.nativeTextFont()).padding(.horizontal, 12).frame(width: 80, height: 44)
                            .background(Theme.control, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border))
                            .accessibilityLabel("Time Before Event")
                        Menu {
                            ForEach(["Days", "Hours"], id: \.self) { unit in
                                Button(unit) { update(reminder.id) { $0.unit = unit } }
                            }
                        } label: { menuLabel(reminder.unit) }
                            .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden).frame(maxWidth: .infinity).accessibilityLabel("Days or Hours").accessibilityValue(reminder.unit)
                        Button {
                            reminders.removeAll { $0.id == reminder.id }
                            amountDrafts.removeValue(forKey: reminder.id)
                        } label: {
                            ActionIcon(symbol: "trash", size: 20)
                        }.buttonStyle(ScroogeButtonStyle(horizontalPadding: 11))
                            .modifier(ImmediateReferenceTooltip(text: "Remove This Reminder from the Schedule")).accessibilityLabel("Remove Reminder")
                    }
                }
            }
            if amountError {
                Text("Enter a Positive Whole Number").font(.reference(size: 12))
                    .foregroundStyle(Color(hex: "#F05B69"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button { reminders.append(TimedReminder(amount: 1, unit: "Days", severity: .info)) } label: { ActionLabel(title: "Add Reminder", symbol: "plus") }.buttonStyle(ScroogeButtonStyle())
        }
        .onChange(of: amountError, initial: true) { _, invalid in onValidationChange(invalid) }
    }
    private func menuLabel(_ title: String, color: Color = .white) -> some View {
        HStack {
            Text(title).font(ReferenceTypography.nativeTextFont()).foregroundStyle(color)
            Spacer()
            ReferenceDropdownChevron().foregroundStyle(Theme.secondary)
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
        var copy = reminders
        guard let index = copy.firstIndex(where: { $0.id == id }) else { return }
        let draft = amountDrafts[id] ?? String(copy[index].amount)
        guard let amount = Int32(draft.trimmingCharacters(in: .whitespacesAndNewlines)), amount > 0 else {
            return
        }
        copy[index].amount = Int(amount)
        change(&copy[index])
        reminders = copy
    }
}
struct QuietHoursControl: View {
    @Environment(\.isEnabled) private var isEnabled
    @FocusState private var focusedBoundary: String?
    @Binding var start: Int
    @Binding var end: Int
    @State private var trackWidth: CGFloat = 800
    @State private var movingStart = false
    @State private var dragging = false
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
                        for x in [a, b] {
                            let circle = Path(ellipseIn: CGRect(x: x - 12, y: y - 12, width: 24, height: 24))
                            context.fill(circle, with: .color(Theme.accent))
                            context.stroke(circle, with: .color(Color(hex: "#7160B4")), lineWidth: 3)
                        }
                        if let focusedBoundary {
                            let x = focusedBoundary == "Quiet Hours Start" ? a : b
                            context.stroke(Path(ellipseIn: CGRect(x: x - 16, y: y - 16, width: 32, height: 32)),
                                           with: .color(.white), lineWidth: 2)
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("quietHours")).onChanged { event in
                        guard isEnabled, span > 0 else { return }
                        if !dragging {
                            let fromStart = abs(event.startLocation.x - a)
                            let fromEnd = abs(event.startLocation.x - b)
                            movingStart = fromStart == fromEnd ? !movingStart : fromStart < fromEnd
                            dragging = true
                            focusedBoundary = movingStart ? "Quiet Hours Start" : "Quiet Hours End"
                        }
                        let fraction = min(1, max(0, (event.location.x - 32) / span))
                        let hour = (Int((fraction * 24).rounded(.toNearestOrEven)) + 12) % 24
                        if movingStart { start = hour } else { end = hour }
                    }.onEnded { _ in dragging = false })
                    ForEach(0..<5) { index in
                        Text(["12 PM", "6 PM", "12 AM", "6 AM", "12 PM"][index])
                            .font(.reference(size: 16)).foregroundStyle(Theme.accent)
                            .frame(width: 64, height: 24).position(x: 32 + span * Double(index) / 4, y: y + 34)
                    }
                    handle(value: $start, x: a, width: geometry.size.width, label: "Quiet Hours Start", labelY: 16)
                    handle(value: $end, x: b, width: geometry.size.width, label: "Quiet Hours End", labelY: closeLabels ? 38 : 16)
                }.coordinateSpace(name: "quietHours")
            }
            .frame(height: closeLabels ? 116 : 94)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { trackWidth = $0 }
            Text(summary).font(.reference(size: 16)).referenceClassicLineMetrics(size: 16).foregroundStyle(Theme.accent)
        }
        .onChange(of: isEnabled) { _, enabled in
            if !enabled { focusedBoundary = nil; dragging = false }
        }
    }
    private func handle(value: Binding<Int>, x: CGFloat, width: CGFloat, label: String, labelY: CGFloat) -> some View {
        Button { focusedBoundary = label } label: {
            Text(hour(value.wrappedValue)).font(ReferenceTypography.nativeTextFont(size: 16))
                .foregroundStyle(Theme.primaryText).frame(width: 80, height: 32)
                .contentShape(Rectangle())
        }.buttonStyle(.plain)
        .focusable().focused($focusedBoundary, equals: label).focusEffectDisabled()
        .onKeyPress(keys: [.leftArrow, .rightArrow, .upArrow, .downArrow]) { press in
            guard isEnabled else { return .ignored }
            let change = press.key == .leftArrow || press.key == .downArrow ? -1 : 1
            value.wrappedValue = (value.wrappedValue + change + 24) % 24
            return .handled
        }
        .accessibilityElement(children: .ignore).accessibilityLabel(label).accessibilityValue(hour(value.wrappedValue))
        .accessibilityAdjustableAction { direction in
            guard isEnabled else { return }
            value.wrappedValue = (value.wrappedValue + (direction == .increment ? 1 : 23)) % 24
        }
        .position(x: min(max(x, 53), width - 53), y: labelY)
    }
    private func hour(_ value: Int) -> String { "\(value % 12 == 0 ? 12 : value % 12) \(value < 12 ? "AM" : "PM")" }
}

private struct SettingsInfoIcon: View {
    let text: String
    var body: some View {
        Text("\u{E946}").font(ReferenceTypography.iconFont(size: 16)).accessibilityLabel("Information")
            .foregroundStyle(Color(hex: "#B5A0F4")).frame(width: 20)
            .modifier(ImmediateReferenceTooltip(text: text)).accessibilityLabel(text)
    }
}

private enum SettingsHelpCopy {
    static let values: [String: String] = [
        "Popup Notifications": "Show popup alerts when an enabled alert rule is triggered",
        "Alert on Icon": "Show alert status on the app icon, even when popup notifications are off",
        "Notification Sounds": "Play the selected sounds for alerts and notification actions",
        "Monitor This Account": "Pause automatic usage checks and alerts when off. Your saved connection stays in place.",
        "Capacity Exhausted": "Alert when a usage limit reaches 0% remaining. Enable the alarm on that limit's dashboard row to receive this alert.",
        "Capacity Restored": "Alert when a previously exhausted limit has capacity again and the provider confirms usage is allowed. Enable the alarm on that limit's dashboard row to receive this alert.",
        "Reset Expiry Reminders": "Remind you before an unused earned reset expires, using Earned Reset Expiration Alerts in global Settings. Expiration does not refresh your quota. At least one dashboard row alarm for this account must be on.",
        "Keep Monitoring When Window Closes": "Keep checking usage in the menu bar after closing the window. Use Quit from the menu bar menu to stop Scrooge.",
        "Launch at Sign-In": "Start Scrooge automatically when you sign in to your Mac",
        "Notifications": "Popup notifications show triggered alerts. Alert on Icon keeps alert status visible on the app icon, even when popups are off.",
        "Sounds": "Choose a sound style and volume for alerts and notification actions. Preview buttons play each sound at the selected volume.",
        "App Behavior": "Keep monitoring after closing the window by leaving Scrooge in the menu bar. Use Quit in the menu bar menu to stop it. Launch at your Mac Sign-In starts Scrooge automatically.",
        "Account": "Name and color identify this account. Polling controls how often usage is checked. Turning monitoring off pauses checks and alerts while keeping the saved connection.",
        "Connection": "Sign in again to renew the connection while keeping settings. Removing the connection only removes it from Scrooge; your provider account is unaffected.",
        "Time Zone": "Use this time zone for displayed dates, reset times, and quiet hours",
        "Quiet Hours": "Keep monitoring while notification delivery is quiet during the selected hours. Drag the start and end handles or use arrow keys in one-hour steps.",
        "Default Alert Levels": "Alerts use capacity remaining, not used. Critical must be below Warning; Info must be at or above Warning. Adjust individual limits on their dashboard bars.",
        "Earned Reset Expiration Alerts": "Reminders before an earned reset expires. Expiration does not refresh your quota. Each row sets severity and lead time in days or hours. Reminders sort from longest to shortest lead time.",
        "Quota Refresh Alerts": "Reminders before a scheduled quota refresh, separate from earned reset expirations. Each row sets severity and lead time in days or hours. Reminders sort from longest to shortest lead time.",
        "Available Resets": "Unused earned resets reported by this provider, with their expiration times when available",
    ]
}

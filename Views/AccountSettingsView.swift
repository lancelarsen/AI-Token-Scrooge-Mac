import SwiftUI

struct AccountSettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let accountID: String
    let hostSize: CGSize
    let reconnect: (ProviderAccount) -> Void
    @State private var newColor = Color(hex: "#B5A0F4")
    @State private var showColor = false
    @State private var isClosing = false
    @State private var confirmRemove = false
    @State private var nicknameDraft = ""
    private let pollingHelp = "How often Scrooge automatically checks this account for updated usage, from 1 to 30 minutes. Shorter intervals show changes sooner; longer intervals make fewer requests. Changes save automatically."
    private var panelSize: CGSize {
        CGSize(width: min(1000, max(640, hostSize.width - 48)),
               height: min(800, max(400, hostSize.height - 64)))
    }
    @FocusState private var editingNickname: Bool
    private var account: ProviderAccount? { store.state.accounts.first { $0.id == accountID } }
    private var lineColors: [String] {
        var seen = Set<String>()
        let selected = account.map { $0.resolvedLineColor(plan: store.state.snapshots[$0.id]?.planType) }
        return (Theme.palette + store.state.settings.customColors + [selected].compactMap { $0 })
            .map { $0.uppercased() }
            .filter { hex in
                hex.count == 7 && hex.first == "#" && hex.dropFirst().allSatisfy(\.isHexDigit) && seen.insert(hex).inserted
            }
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) { ActionIcon(symbol: "person", size: 26).frame(width: 29).environment(\.actionForeground, Theme.accent); Text(accountTitle).font(.reference(size: 26, weight: .semibold)).foregroundStyle(Theme.primaryText).referenceFallbackLineMetrics(size: 26); Spacer(); SettingsCloseButton(isClosing: $isClosing, flushDraft: saveNickname) }.padding(.horizontal, 20).padding(.vertical, 12)
            SettingsScrollView {
                if let account {
                    VStack(spacing: 12) {
                        SettingsCard(title: "Account", symbol: "person", help: "Name and color identify this account. Polling controls how often usage is checked. Turning monitoring off pauses checks and alerts while keeping the saved connection.") {
                            HStack(spacing: 12) {
                                Text("Account Name").frame(width: 190, alignment: .leading)
                                TextField("Personal, Work", text: $nicknameDraft).textFieldStyle(.plain)
                                    .font(ReferenceTypography.nativeTextFont())
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
                            HStack(spacing: 12) {
                            Text("Line Color").frame(width: 190, height: 32, alignment: .leading)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40, maximum: 40), spacing: 0)], alignment: .leading, spacing: 0) {
                                ForEach(lineColors, id: \.self) { hex in
                                    Button { update { $0.lineColor = hex } } label: {
                                        ZStack { RoundedRectangle(cornerRadius: 9).fill(Color(hex: hex)); if account.resolvedLineColor(plan: store.state.snapshots[account.id]?.planType).caseInsensitiveCompare(hex) == .orderedSame { RoundedRectangle(cornerRadius: 9).stroke(.white, lineWidth: 2); Text("\u{2713}").font(.reference(size: 14)).foregroundStyle(Color(hex: "#141519")) } }.frame(width: 32, height: 32)
                                    }.buttonStyle(.plain).padding(.trailing, 8).padding(.bottom, 8).accessibilityLabel("Line Color \(hex)")
                                }
                                Button {
                                    newColor = Color(hex: account.resolvedLineColor(plan: store.state.snapshots[account.id]?.planType))
                                    showColor = true
                                } label: { Text("+").font(.reference(size: 22)).foregroundStyle(Theme.actionAccent).frame(width: 32, height: 32).background(Theme.control).clipShape(RoundedRectangle(cornerRadius: 9)).overlay(RoundedRectangle(cornerRadius: 9).stroke(Color(hex: "#65577F"), lineWidth: 1)) }.buttonStyle(.plain).padding(.trailing, 8).padding(.bottom, 8)
                                    .modifier(ImmediateReferenceTooltip(text: "Add Custom Line Color"))
                                    .accessibilityLabel("Add Custom Line Color")
                                    .sheet(isPresented: $showColor) {
                                        DetailsDialog(title: "Add Line Color", width: 360, maximumHeight: 640, closeTitle: "Cancel", tabToFooter: true, primaryTitle: "Add Color", primaryAction: {
                                            let hex = newColor.hex; store.edit { state in
                                                if !state.settings.customColors.contains(hex) { state.settings.customColors.append(hex) }
                                                if let i = state.accounts.firstIndex(where: { $0.id == accountID }) { state.accounts[i].lineColor = hex }
                                            }; showColor = false
                                        }, close: { showColor = false }) {
                                            ScrollViewReader { proxy in
                                                ScrollView {
                                                    InlineLineColorEditor(color: $newColor) { target in
                                                        proxy.scrollTo(target, anchor: target == .channels ? .bottom : .top)
                                                    }
                                                }
                                            }.frame(height: 420)
                                        }
                                    }
                            }
                            }
                            HStack(spacing: 12) {
                                HStack(spacing: 6) {
                                infoIcon(pollingHelp)
                                Text("Polling Interval: \(account.effectivePollingMinutes) Min").frame(width: 190, alignment: .leading)
                                    .modifier(ImmediateReferenceTooltip(text: pollingHelp))
                                }
                                MinuteSlider(value: Binding(get: { account.effectivePollingMinutes }, set: { value in update { $0.pollingMinutes = value } })).frame(height: 44)
                            }
                            HStack(spacing: 6) {
                            infoIcon("Pause automatic usage checks and alerts when off. Your saved connection stays in place.")
                            Toggle("Monitor This Account", isOn: Binding(get: { account.enabled }, set: { value in update { $0.enabled = value; $0.generation = UUID() } }))
                                .toggleStyle(ScroogeSwitchStyle()).frame(minHeight: 36)
                                .modifier(ImmediateReferenceTooltip(text: "Pause automatic usage checks and alerts when off. Your saved connection stays in place."))
                            }
                        }
                        if let savedSnapshot = store.state.snapshots[accountID], savedSnapshot.belongs(to: account), let reserve = savedSnapshot.reserve {
                            SettingsCard(title: "Available Resets", symbol: "folder", help: "Unused earned resets reported by this provider, with their expiration times when available") {
                                Text("\(reserve.availableCount.map(String.init) ?? "Unknown") Available").font(.reference(size: 20))
                                if let credits = reserve.credits {
                                    ForEach(credits) { credit in
                                        Text("Expires \(Format.date(credit.expiresAt, zone: store.state.settings.zone))").foregroundStyle(Theme.amber)
                                    }
                                } else { Text("Credit Details Unavailable").foregroundStyle(Theme.secondary) }
                                if reserve.hasPartialDetails { Text("Some reset details are not supplied by the provider.").font(.reference(size: 12)).foregroundStyle(Theme.secondary) }
                            }
                        }
                        SettingsCard(title: "Other Alerts", symbol: "desktopcomputer", description: "Warning and critical levels are adjusted directly on the dashboard bars.") {
                            ruleToggle("Capacity Exhausted", path: \.exhausted, help: "Alert when a usage limit reaches 0% remaining. Enable the alarm on that limit's dashboard row to receive this alert.")
                            ruleToggle("Capacity Restored", path: \.restored, help: "Alert when a previously exhausted limit has capacity again and the provider confirms usage is allowed. Enable the alarm on that limit's dashboard row to receive this alert.")
                            ruleToggle("Reset Expiry Reminders", path: \.expiry, help: "Remind you before an unused earned reset expires, using Earned Reset Expiration Alerts in global Settings. Expiration does not refresh your quota. At least one dashboard row alarm for this account must be on.")
                        }
                        SettingsCard(title: "Connection", symbol: "link", help: "Sign in again to renew the connection while keeping settings. Removing the connection only removes it from Scrooge; your provider account is unaffected.") {
                            Text("Sign in again only if this account needs a new connection. Your saved settings stay in place.").font(.reference(size: 13)).foregroundStyle(Theme.secondary)
                            Button {
                                guard !isClosing else { return }
                                isClosing = true
                                saveNickname()
                                Task {
                                    if await store.finishSettingsEdits(), let current = self.account { reconnect(current) }
                                    isClosing = false
                                }
                            } label: { DialogActionLabel(title: "Sign In Again").frame(maxWidth: .infinity, alignment: .leading) }.buttonStyle(ScroogeButtonStyle()).disabled(store.isDemo)
                            Button(role: .destructive) { confirmRemove = true } label: { DialogActionLabel(title: "Remove Account").frame(maxWidth: .infinity, alignment: .leading) }.buttonStyle(ScroogeButtonStyle()).disabled(store.isDemo)
                        }
                    }.padding(.horizontal, 16).padding(.vertical, 12).frame(width: min(960, panelSize.width - 2 - 24)).frame(maxWidth: .infinity)
                }
            }.disabled(isClosing)
            if let error = store.settingsSaveError {
                Text(error).foregroundStyle(Theme.amber)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing).padding(.horizontal, 24)
                    .accessibilityIdentifier("settingsSaveStatus")
            }
        }.font(.reference(size: 14)).foregroundStyle(Theme.primaryText).referencePanelFrame(size: panelSize).preferredColorScheme(.dark).tint(Theme.accent)
        .interactiveDismissDisabled()
        .onAppear {
            nicknameDraft = account?.nickname ?? ""

        }
        .onDisappear { saveNickname() }
        .sheet(isPresented: $confirmRemove) {
            ConfirmationDetailsDialog(title: "Remove Account?",
                message: "This removes the saved connection from Scrooge. Your provider account is unaffected.",
                actionTitle: "Remove", cancel: { confirmRemove = false }) {
                    confirmRemove = false
                    Task {
                        await store.removeAccount(accountID)
                        if account == nil { dismiss() }
                    }
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
        } })).toggleStyle(ScroogeSwitchStyle()).frame(minHeight: 36).modifier(ImmediateReferenceTooltip(text: help))
        }
    }
    private func infoIcon(_ help: String) -> some View {
        Text("\u{E946}").font(ReferenceTypography.iconFont(size: 16)).accessibilityLabel("Information").foregroundStyle(Color(hex: "#B5A0F4"))
            .frame(width: 20).modifier(ImmediateReferenceTooltip(text: help)).accessibilityLabel(help)
    }
}

struct MinuteSlider: View {
    @Binding var value: Int
    @FocusState private var focused: Bool
    @State private var keyboardFocus = false
    @State private var dragOrigin: CGFloat?
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
                if focused && keyboardFocus {
                    context.stroke(Path(roundedRect: CGRect(x: x - 14, y: y - 22, width: 28, height: 44), cornerRadius: 3),
                                   with: .color(Theme.accent), lineWidth: 1.5)
                }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { event in
                guard width > 0 else { return }
                if dragOrigin == nil {
                    // The Windows thumb has a 28-point hit area and drags from
                    // its snapped anchor, preserving an off-center grab.
                    dragOrigin = abs(event.startLocation.x - x) <= 14 ? x : event.startLocation.x
                }
                focused = true; keyboardFocus = false
                let position = (dragOrigin ?? x) + event.translation.width
                setMinute(Int(((position - 14) / width * 29).rounded()) + 1)
            }.onEnded { _ in dragOrigin = nil })
        }
        .focusable().focused($focused).focusEffectDisabled()
        .onChange(of: focused) { _, active in if !active { keyboardFocus = false; dragOrigin = nil } }
        .onKeyPress(.leftArrow) { keyMinute(value - 1); return .handled }
        .onKeyPress(.downArrow) { keyMinute(value - 1); return .handled }
        .onKeyPress(.rightArrow) { keyMinute(value + 1); return .handled }
        .onKeyPress(.upArrow) { keyMinute(value + 1); return .handled }
        .onKeyPress(.home) { keyMinute(1); return .handled }
        .onKeyPress(.end) { keyMinute(30); return .handled }
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
    private func keyMinute(_ proposed: Int) {
        keyboardFocus = true
        setMinute(proposed)
    }
    private func setMinute(_ proposed: Int) {
        let next = min(30, max(1, proposed))
        if value != next { value = next }
    }
}


/// Inline opaque-color editor matching the Windows color dialog's control arrangement.
private enum ColorEditorSection: Hashable { case spectrum, channels }

private struct InlineLineColorEditor: View {
    @Binding var color: Color
    let reveal: (ColorEditorSection) -> Void
    @FocusState private var focusedChannel: Int?
    @Environment(\.appearsActive) private var appearsActive
    @State private var hue = 0.0
    @State private var saturation = 0.0
    @State private var brightness = 1.0
    @State private var hexDraft = ""
    @State private var mode = "RGB"
    @FocusState private var spectrumFocused: Bool
    @State private var spectrumHovered = false
    @State private var spectrumPressed = false
    @State private var spectrumKeyboardFocus = false
    @FocusState private var brightnessFocused: Bool
    @State private var brightnessKeyboardFocus = false
    @State private var brightnessPressed = false

    private var spectrumX: Double { min(hue * 360 / 359, 1) }
    private var colorName: String? { WindowsColorNames.name(hex: color.hex) }
    private var valueLabel: String { "Value \(Int((brightness * 100).rounded()))" }
    private var brightnessDescription: String {
        colorName.map { "\(valueLabel) (\($0))" } ?? valueLabel
    }
    private var spectrumDescription: String {
        [colorName, "Hue \(Int((hue * 360).rounded()))", "Saturation \(Int((saturation * 100).rounded()))", valueLabel]
            .compactMap { $0 }.joined(separator: ", ")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                GeometryReader { geometry in
                    ZStack {
                        if let image = LineColorSpectrum.image {
                            Image(nsImage: image).resizable().interpolation(.high)
                        }
                        SpectrumSelectionIndicator(light: SpectrumSelectionContrast.usesLightStroke(hue: hue, saturation: saturation),
                                                   hovered: spectrumHovered, pressed: spectrumPressed,
                                                   keyboardFocused: spectrumFocused && spectrumKeyboardFocus)
                            .anchorPreference(key: ColorFocusTip.self, value: .bounds) { anchor in
                                guard spectrumFocused, let colorName else { return nil }
                                return ColorFocusTip.Target(anchor: anchor, text: colorName)
                            }
                            .position(x: spectrumX * geometry.size.width, y: (1 - saturation) * geometry.size.height)
                    }.clipShape(RoundedRectangle(cornerRadius: 10)).contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                            spectrumPressed = true; spectrumKeyboardFocus = false; spectrumFocused = true
                            hue = min(1, max(0, value.location.x / geometry.size.width)) * 359 / 360
                            saturation = 1 - min(1, max(0, value.location.y / geometry.size.height))
                            publish()
                        }.onEnded { _ in spectrumPressed = false })
                        .onHover { spectrumHovered = $0 }
                        .focusable().focused($spectrumFocused).focusEffectDisabled()
                        .onChange(of: spectrumFocused) { _, focused in
                            if !focused { spectrumKeyboardFocus = false; spectrumPressed = false }
                            else if !spectrumPressed { spectrumKeyboardFocus = true; reveal(.spectrum) }
                        }
                        .onKeyPress(keys: [.leftArrow, .rightArrow, .upArrow, .downArrow]) { press in
                            spectrumKeyboardFocus = true
                            let horizontal = press.key == .leftArrow || press.key == .rightArrow
                            let increasing = press.key == .rightArrow || press.key == .upArrow
                            adjust(horizontal ? .hue : .saturation, increasing: increasing,
                                   byName: press.modifiers.contains(.control))
                            publish(); return .handled
                        }
                        .accessibilityLabel("Color Spectrum")
                        .accessibilityValue(spectrumDescription)
                }.frame(height: 256)
                RoundedRectangle(cornerRadius: 10).fill(color).frame(width: 44, height: 256)
                    .accessibilityLabel("Selected Color").accessibilityValue(color.hex)
            }.padding(.bottom, 16).id(ColorEditorSection.spectrum)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(LinearGradient(colors: [.black, Color(hue: hue, saturation: saturation, brightness: 1)], startPoint: .leading, endPoint: .trailing)).frame(height: 12)
                    Circle().fill(.white).overlay(Circle().stroke(Color(hex: "#45464D"), lineWidth: 2))
                        .frame(width: 14, height: 14)
                        .overlay {
                            if brightnessFocused && brightnessKeyboardFocus {
                                Circle().stroke(Theme.accent, lineWidth: 2).frame(width: 22, height: 22)
                            }
                        }
                        .anchorPreference(key: ColorFocusTip.self, value: .bounds) { anchor in
                            brightnessFocused ? ColorFocusTip.Target(anchor: anchor, text: brightnessDescription) : nil
                        }
                        .offset(x: brightness * max(0, geometry.size.width - 14))
                }.frame(height: 32).contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                        brightnessPressed = true; brightnessKeyboardFocus = false; brightnessFocused = true
                        brightness = min(1, max(0, (value.location.x - 7) / max(1, geometry.size.width - 14)))
                        publish()
                    }.onEnded { _ in brightnessPressed = false })
                    .focusable().focused($brightnessFocused).focusEffectDisabled()
                    .onChange(of: brightnessFocused) { _, focused in
                        if !focused { brightnessKeyboardFocus = false; brightnessPressed = false }
                        else if !brightnessPressed { brightnessKeyboardFocus = true }
                    }
                    .onKeyPress(keys: [.leftArrow, .rightArrow, .upArrow, .downArrow]) { press in
                        brightnessKeyboardFocus = true
                        let increasing = press.key == .rightArrow || press.key == .upArrow
                        adjust(.value, increasing: increasing, byName: press.modifiers.contains(.control))
                        publish(); return .handled
                    }
                    .accessibilityLabel("Brightness").accessibilityValue(brightnessDescription)
                    .accessibilityAdjustableAction { direction in
                        brightness = min(1, max(0, brightness + (direction == .increment ? 0.01 : -0.01)))
                        publish()
                    }
            }.frame(height: 32).padding(.bottom, 6)
            HStack {
                HStack {
                    Text(mode)
                    Spacer()
                    ReferenceDropdownChevron()
                }.padding(.horizontal, 12).frame(width: 120, height: 32)
                    .background(Color(hex: "#303138"), in: RoundedRectangle(cornerRadius: 10))
                    .accessibilityHidden(true)
                    .overlay { ColorModelPopup(selection: $mode) }
                Spacer()
                TextField("Hex Color", text: $hexDraft)
                    .onChange(of: hexDraft) { _, value in
                        let digits = value.hasPrefix("#") ? String(value.dropFirst()) : value
                        if digits.count == 6, UInt64(digits, radix: 16) != nil,
                           "#" + digits.uppercased() != color.hex {
                            // Only external hex edits should replace HSV coordinates.
                            // Re-decoding our own black/gray output would discard hue.
                            let nextColor = Color(hex: digits)
                            color = nextColor; loadComponents(nextColor)
                        }
                    }.modifier(ColorEntryStyle()).frame(width: 132)
            }.padding(.bottom, 12)
            VStack(spacing: 12) {
                ForEach(0..<3) { index in
                    HStack(spacing: 8) {
                        TextField(channelName(index), value: channel(index), format: .number)
                            .modifier(ColorEntryStyle()).frame(width: 120)
                            .focused($focusedChannel, equals: index)
                        Text(channelName(index)).font(ReferenceTypography.nativeTextFont())
                        Spacer()
                    }
                }
            }.id(ColorEditorSection.channels)
                .onChange(of: focusedChannel) { _, index in
                    if index != nil { reveal(.channels) }
                }
        }.textFieldStyle(.plain).font(ReferenceTypography.nativeTextFont()).foregroundStyle(Theme.primaryText)
            .textSelection(.disabled)
            .padding(.vertical, 4)
            .overlayPreferenceValue(ColorFocusTip.self) { target in
                if let target, appearsActive {
                    GeometryReader { geometry in
                        let frame = geometry[target.anchor]
                        let bounds = CGRect(origin: .zero, size: geometry.size)
                        let visible = geometry.bounds(of: .scrollView).map { bounds.intersection($0) } ?? bounds
                        if visible.intersects(frame) {
                            ReferenceHelpTooltip(text: target.text, width: ReferenceHelpTooltip.width(for: target.text, availableWidth: visible.width))
                                .alignmentGuide(.leading) { size in
                                    -min(max(visible.minX, frame.midX - size.width / 2), visible.maxX - size.width)
                                }
                                .alignmentGuide(.top) { size in
                                    let above = frame.minY - 20 - size.height
                                    return -(above >= visible.minY ? above : min(frame.maxY + 20, visible.maxY - size.height))
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        }
                    }.allowsHitTesting(false).accessibilityHidden(true)
                }
            }
            .onAppear { loadComponents(); hexDraft = color.hex }
    }
    private enum HSVChannel { case hue, saturation, value }
    private func adjust(_ channel: HSVChannel, increasing: Bool, byName: Bool) {
        let isHue = channel == .hue
        let scale = isHue ? 360.0 : 100.0
        let maximum = isHue ? 359.0 : 100.0
        let fraction: Double
        switch channel {
        case .hue: fraction = hue
        case .saturation: fraction = saturation
        case .value: fraction = brightness
        }
        let next: Double
        if byName {
            let nameScale = isHue ? scale : 1.0
            next = ColorPickerChannel.nextNamed(fraction * nameScale, maximum: isHue ? maximum : 1, step: isHue ? 1 : 0.01,
                                                increasing: increasing, wraps: channel != .value, wrapPeriod: nameScale) { value in
                let component = value / nameScale
                let candidate = Color(hue: isHue ? component : hue,
                                      saturation: channel == .saturation ? component : saturation,
                                      brightness: channel == .value ? component : brightness)
                return WindowsColorNames.name(hex: candidate.hex)
            } / nameScale
        } else {
            next = ColorPickerChannel.stepped(fraction * scale, maximum: maximum, increasing: increasing,
                                              wraps: channel != .value) / scale
        }
        switch channel {
        case .hue: hue = next
        case .saturation: saturation = next
        case .value: brightness = next
        }
    }
    private func channelName(_ index: Int) -> String {
        (mode == "RGB" ? ["Red", "Green", "Blue"] : ["Hue", "Saturation", "Value"])[index]
    }
    private func displayedChannel(_ index: Int) -> Int {
        if mode == "HSV" { return Int(([hue * 360, saturation * 100, brightness * 100][index]).rounded()) }
        let rgb = NSColor(color).usingColorSpace(.sRGB) ?? .black
        return Int(([rgb.redComponent, rgb.greenComponent, rgb.blueComponent][index] * 255).rounded())
    }

    private func channel(_ index: Int) -> Binding<Int> {
        Binding(get: { displayedChannel(index) }, set: { value in
            // TextField commits its rounded representation on blur, even if the
            // user only pressed Tab. Keep the original color until an edit.
            guard value != displayedChannel(index) else { return }
            if mode == "HSV" {
                let fraction = Double(max(0, min(index == 0 ? 359 : 100, value))) / (index == 0 ? 360 : 100)
                if index == 0 { hue = fraction } else if index == 1 { saturation = fraction } else { brightness = fraction }
                publish()
            } else {
                let rgb = NSColor(color).usingColorSpace(.sRGB) ?? .black
                var channels = [rgb.redComponent, rgb.greenComponent, rgb.blueComponent]
                channels[index] = Double(max(0, min(255, value))) / 255
                let nextColor = Color(red: channels[0], green: channels[1], blue: channels[2])
                color = nextColor
                loadComponents(nextColor); hexDraft = nextColor.hex
            }
        })
    }
    private func publish() {
        let nextColor = Color(hue: hue, saturation: saturation, brightness: brightness)
        color = nextColor
        hexDraft = nextColor.hex
    }
    private func loadComponents(_ updatedColor: Color? = nil) {
        guard let rgb = NSColor(updatedColor ?? color).usingColorSpace(.sRGB) else { return }
        // AppKit can return a hue just below one for pure sRGB red after
        // converting color spaces. Use the editor's exact byte values so red
        // starts at zero degrees, the same end of the spectrum as WinUI.
        let r = (rgb.redComponent * 255).rounded()
        let g = (rgb.greenComponent * 255).rounded()
        let b = (rgb.blueComponent * 255).rounded()
        hue = r >= g && g == b ? 0 : rgb.hueComponent
        saturation = rgb.saturationComponent
        brightness = rgb.brightnessComponent
    }
}

/// Keep the native popup in the key-view loop even when macOS limits Tab to
/// editing controls. SwiftUI supplies the visible label and owns the selection.
private struct ColorModelPopup: NSViewRepresentable {
    @Binding var selection: String

    final class Control: NSPopUpButton {
        var didSelect: ((String) -> Void)?
        override var canBecomeKeyView: Bool { isEnabled && !isHiddenOrHasHiddenAncestor }
        override var acceptsFirstResponder: Bool { isEnabled }

        @objc func selectionChanged() {
            if let selected = titleOfSelectedItem { didSelect?(selected) }
        }

        override func keyDown(with event: NSEvent) {
            switch event.keyCode {
            case 36, 49, 76, 125, 126: performClick(nil) // Return, Space, Enter, Down, Up
            case 123, 124:
                selectItem(at: event.keyCode == 123 ? 0 : 1)
                selectionChanged()
            default: super.keyDown(with: event)
            }
        }

        override func becomeFirstResponder() -> Bool {
            let accepted = super.becomeFirstResponder()
            needsDisplay = true
            return accepted
        }

        override func resignFirstResponder() -> Bool {
            let resigned = super.resignFirstResponder()
            needsDisplay = true
            return resigned
        }

        override func draw(_ dirtyRect: NSRect) {
            guard window?.firstResponder === self else { return }
            NSColor(Theme.accent).setStroke()
            let ring = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 9, yRadius: 9)
            ring.lineWidth = 2
            ring.stroke()
        }
    }

    func makeNSView(context: Context) -> Control {
        let control = Control(frame: .zero, pullsDown: false)
        control.addItems(withTitles: ["RGB", "HSV"])
        control.setAccessibilityLabel("Color Model")
        control.focusRingType = .none
        control.target = control
        control.action = #selector(Control.selectionChanged)
        return control
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: Control, context: Context) -> CGSize? {
        proposal.replacingUnspecifiedDimensions(by: CGSize(width: 120, height: 32))
    }

    func updateNSView(_ control: Control, context: Context) {
        control.didSelect = { selection = $0 }
        control.selectItem(withTitle: selection)
    }
}

/// Resolve the indicator's anchor at the editor so the tip tracks scrolling
/// without stealing focus or being clipped by the spectrum's rounded corners.
private enum ColorFocusTip: PreferenceKey {
    struct Target {
        let anchor: Anchor<CGRect>
        let text: String
    }
    static var defaultValue: Target? { nil }
    static func reduce(value: inout Target?, nextValue: () -> Target?) {
        if let target = nextValue() { value = target }
    }
}

private struct ColorEntryStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(.horizontal, 12).frame(height: 32)
            .background(Color(hex: "#303138"), in: RoundedRectangle(cornerRadius: 10))
            .overlay(alignment: .bottom) { Rectangle().fill(Theme.secondary).frame(height: 1).padding(.horizontal, 10) }
    }
}

/// Immutable HSV spectrum in sRGB; avoids perceptual interpolation between hue stops.
private enum LineColorSpectrum {
    static let image: NSImage? = {
        let side = 512
        var pixels = [UInt8](repeating: 255, count: side * side * 4)
        for y in 0..<side {
            let saturation = 1 - Double(y) / Double(side - 1)
            for x in 0..<side {
                let sector = Double(x) / Double(side - 1) * (359.0 / 60)
                let fraction = sector - floor(sector)
                let full: [Double]
                switch Int(sector) % 6 {
                case 0: full = [1, fraction, 0]
                case 1: full = [1 - fraction, 1, 0]
                case 2: full = [0, 1, fraction]
                case 3: full = [0, 1 - fraction, 1]
                case 4: full = [fraction, 0, 1]
                default: full = [1, 0, 1 - fraction]
                }
                let offset = (y * side + x) * 4
                for channel in 0..<3 {
                    pixels[offset + channel] = UInt8(((1 - saturation + saturation * full[channel]) * 255).rounded())
                }
            }
        }
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let provider = CGDataProvider(data: Data(pixels) as CFData),
              let image = CGImage(width: side, height: side, bitsPerComponent: 8, bitsPerPixel: 32,
                  bytesPerRow: side * 4, space: space,
                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                  provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else { return nil }
        return NSImage(cgImage: image, size: NSSize(width: 256, height: 256))
    }()
}

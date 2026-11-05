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
            HStack(spacing: 10) { ActionIcon(symbol: "person", size: 26).frame(width: 29).environment(\.actionForeground, Theme.accent); Text(accountTitle).font(.system(size: 26, weight: .semibold)).foregroundStyle(Theme.primaryText); Spacer(); Button { dismiss() } label: { DialogActionLabel(title: "Close", symbol: "xmark") }.buttonStyle(ScroogeButtonStyle()).keyboardShortcut(.cancelAction) }.padding(.horizontal, 20).padding(.vertical, 12)
            SettingsScrollView {
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
                            HStack(spacing: 12) {
                            Text("Line Color").frame(width: 190, height: 32, alignment: .leading)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 32, maximum: 32), spacing: 8)], alignment: .leading, spacing: 8) {
                                ForEach(lineColors, id: \.self) { hex in
                                    Button { update { $0.lineColor = hex } } label: {
                                        ZStack { RoundedRectangle(cornerRadius: 9).fill(Color(hex: hex)); if account.resolvedLineColor(plan: store.state.snapshots[account.id]?.planType).caseInsensitiveCompare(hex) == .orderedSame { RoundedRectangle(cornerRadius: 9).stroke(.white, lineWidth: 2); Image(systemName: "checkmark").foregroundStyle(.black) } }.frame(width: 32, height: 32)
                                    }.buttonStyle(.plain).accessibilityLabel("Line Color \(hex)")
                                }
                                Button {
                                    newColor = Color(hex: account.resolvedLineColor(plan: store.state.snapshots[account.id]?.planType))
                                    showColor = true
                                } label: { ActionIcon(symbol: "plus", size: 20).frame(width: 32, height: 32).background(Theme.control).clipShape(RoundedRectangle(cornerRadius: 9)).overlay(RoundedRectangle(cornerRadius: 9).stroke(Color(hex: "#65577F"), lineWidth: 1)) }.buttonStyle(.plain)
                                    .modifier(ImmediateReferenceTooltip(text: "Add Custom Line Color"))
                                    .accessibilityLabel("Add Custom Line Color")
                                    .sheet(isPresented: $showColor) {
                                        DetailsDialog(width: 360, maximumHeight: 640, closeTitle: "Cancel", primaryTitle: "Add Color", primarySymbol: "plus", primaryAction: {
                                            let hex = newColor.hex; store.edit { state in
                                                if !state.settings.customColors.contains(hex) { state.settings.customColors.append(hex) }
                                                if let i = state.accounts.firstIndex(where: { $0.id == accountID }) { state.accounts[i].lineColor = hex }
                                            }; showColor = false
                                        }, close: { showColor = false }) {
                                            VStack(alignment: .leading, spacing: 16) {
                                                Text("Add Line Color").font(.system(size: 21, weight: .semibold)).foregroundStyle(Theme.accent)
                                                ScrollView { InlineLineColorEditor(color: $newColor) }.frame(height: 420)
                                            }
                                        }
                                    }
                            }.padding(.bottom, 8)
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
                            infoIcon("Pause checks and alerts without removing this connection.")
                            Toggle("Monitor This Account", isOn: Binding(get: { account.enabled }, set: { value in update { $0.enabled = value; $0.generation = UUID() } }))
                                .toggleStyle(ScroogeSwitchStyle()).frame(minHeight: 36)
                                .modifier(ImmediateReferenceTooltip(text: "Pause checks and alerts without removing this connection."))
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
                                if reserve.hasPartialDetails { Text("Some reset details are not supplied by the provider.").font(.system(size: 12)).foregroundStyle(Theme.secondary) }
                            }
                        }
                        SettingsCard(title: "Other Alerts", symbol: "desktopcomputer", description: "Warning and critical levels are adjusted directly on the dashboard bars.") {
                            ruleToggle("Capacity Exhausted", path: \.exhausted, help: "Alert when a monitored allowance has no remaining capacity.")
                            ruleToggle("Capacity Restored", path: \.restored, help: "Alert when an exhausted allowance has capacity again and the provider confirms usage is allowed.")
                            ruleToggle("Reset Expiry Reminders", path: \.expiry, help: "Remind you before available earned resets expire.")
                        }
                        SettingsCard(title: "Connection", symbol: "link", help: "Reconnect this account or remove its saved connection.") {
                            Text("Sign in again only if this account needs a new connection. Your saved settings stay in place.").font(.system(size: 13)).foregroundStyle(Theme.secondary)
                            Button { store.reconnectAccountID = accountID; dismiss(); store.showConnection = true } label: { DialogActionLabel(title: "Sign In Again", symbol: "person").frame(maxWidth: .infinity, alignment: .leading) }.buttonStyle(ScroogeButtonStyle()).disabled(store.isDemo)
                            Button(role: .destructive) { confirmRemove = true } label: { DialogActionLabel(title: "Remove Account", symbol: "trash").frame(maxWidth: .infinity, alignment: .leading) }.buttonStyle(ScroogeButtonStyle()).disabled(store.isDemo)
                        }
                    }.padding(.horizontal, 28).padding(.vertical, 12)
                }
            }
        }.font(.system(size: 14)).foregroundStyle(Theme.primaryText).frame(width: panelSize.width, height: panelSize.height).background(Theme.canvas).preferredColorScheme(.dark).tint(Theme.accent)
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
        } })).toggleStyle(ScroogeSwitchStyle()).frame(minHeight: 36).modifier(ImmediateReferenceTooltip(text: help))
        }
    }
    private func infoIcon(_ help: String) -> some View {
        Image(systemName: "info.circle").font(.system(size: 16)).foregroundStyle(Color(hex: "#B5A0F4"))
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
private struct InlineLineColorEditor: View {
    @Binding var color: Color
    @State private var hue = 0.0
    @State private var saturation = 0.0
    @State private var brightness = 1.0
    @State private var hexDraft = ""
    @State private var mode = "RGB"
    @FocusState private var spectrumFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                GeometryReader { geometry in
                    ZStack {
                        if let image = LineColorSpectrum.image {
                            Image(nsImage: image).resizable().interpolation(.high)
                        }
                        Circle().stroke(.black, lineWidth: 2).background(Circle().stroke(.white, lineWidth: 4))
                            .frame(width: 12, height: 12)
                            .position(x: min(max(hue * geometry.size.width, 7), geometry.size.width - 7),
                                      y: min(max((1 - saturation) * geometry.size.height, 7), geometry.size.height - 7))
                    }.clipShape(RoundedRectangle(cornerRadius: 8)).contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                            hue = min(1, max(0, value.location.x / geometry.size.width))
                            saturation = 1 - min(1, max(0, value.location.y / geometry.size.height))
                            publish()
                        })
                        .focusable().focused($spectrumFocused).focusEffectDisabled()
                        .onKeyPress(keys: [.leftArrow, .rightArrow, .upArrow, .downArrow]) { press in
                            switch press.key {
                            case .leftArrow: hue = max(0, hue - 1 / 360)
                            case .rightArrow: hue = min(1, hue + 1 / 360)
                            case .upArrow: saturation = min(1, saturation + 0.01)
                            default: saturation = max(0, saturation - 0.01)
                            }
                            publish(); return .handled
                        }
                        .accessibilityLabel("Color Spectrum")
                        .accessibilityValue("Hue \(Int(hue * 360)), saturation \(Int(saturation * 100)) percent")
                }.frame(height: 256)
                RoundedRectangle(cornerRadius: 8).fill(color).frame(width: 44, height: 256)
                    .accessibilityLabel("Selected Color").accessibilityValue(color.hex)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(LinearGradient(colors: [.black, Color(hue: hue, saturation: saturation, brightness: 1)], startPoint: .leading, endPoint: .trailing)).frame(height: 12)
                    Circle().fill(.white).overlay(Circle().stroke(Color(hex: "#45464D"), lineWidth: 2))
                        .frame(width: 14, height: 14).offset(x: brightness * max(0, geometry.size.width - 14))
                }.frame(height: 32).contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                        brightness = min(1, max(0, (value.location.x - 7) / max(1, geometry.size.width - 14)))
                        publish()
                    })
                    .accessibilityLabel("Brightness").accessibilityValue("\(Int(brightness * 100)) percent")
                    .accessibilityAdjustableAction { direction in
                        brightness = min(1, max(0, brightness + (direction == .increment ? 0.01 : -0.01)))
                        publish()
                    }
            }.frame(height: 32)
            HStack {
                Menu {
                    Picker("Color Model", selection: $mode) { Text("RGB").tag("RGB"); Text("HSV").tag("HSV") }.pickerStyle(.inline)
                } label: {
                    HStack {
                        Text(mode)
                        Spacer()
                        Image(systemName: "chevron.down").font(.system(size: 10))
                    }.padding(.horizontal, 12).frame(width: 120, height: 32)
                        .background(Color(hex: "#303138"), in: RoundedRectangle(cornerRadius: 8))
                }.menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden)
                    .accessibilityLabel("Color Model").accessibilityValue(mode)
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
            }
            ForEach(0..<3) { index in
                HStack(spacing: 8) {
                    TextField(channelName(index), value: channel(index), format: .number)
                        .modifier(ColorEntryStyle()).frame(width: 120)
                    Text(channelName(index)).font(.system(size: 12))
                    Spacer()
                }
            }
        }.textFieldStyle(.plain).font(.system(size: 13))
            .onAppear { loadComponents(); hexDraft = color.hex }
    }
    private func channelName(_ index: Int) -> String {
        (mode == "RGB" ? ["Red", "Green", "Blue"] : ["Hue", "Saturation", "Value"])[index]
    }
    private func channel(_ index: Int) -> Binding<Int> {
        Binding(get: {
            if mode == "HSV" { return Int(([hue * 360, saturation * 100, brightness * 100][index]).rounded()) }
            let rgb = NSColor(color).usingColorSpace(.sRGB) ?? .black
            return Int(([rgb.redComponent, rgb.greenComponent, rgb.blueComponent][index] * 255).rounded())
        }, set: { value in
            if mode == "HSV" {
                let fraction = Double(max(0, min(index == 0 ? 360 : 100, value))) / (index == 0 ? 360 : 100)
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
        hue = rgb.hueComponent; saturation = rgb.saturationComponent; brightness = rgb.brightnessComponent
    }
}

private struct ColorEntryStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(.horizontal, 12).frame(height: 32)
            .background(Color(hex: "#303138"), in: RoundedRectangle(cornerRadius: 8))
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
                let sector = Double(x) / Double(side - 1) * 6
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

import SwiftUI

extension EnvironmentValues {
    @Entry var dashboardHostSize: CGSize? = nil
}

/// The Windows reference sizes panels against the complete window frame.
/// GeometryReader excludes the native Mac title bar, so observe the owning
/// window directly without changing its appearance or behavior.
struct DashboardWindowSizeReader: NSViewRepresentable {
    var changed: (CGSize) -> Void
    func makeNSView(context: Context) -> FrameView {
        let view = FrameView()
        view.changed = changed
        return view
    }
    func updateNSView(_ view: FrameView, context: Context) {
        view.changed = changed
        view.publishSize()
    }
    static func dismantleNSView(_ view: FrameView, coordinator: ()) { view.stopObserving() }

    final class FrameView: NSView {
        var changed: ((CGSize) -> Void)?
        private var observer: NSObjectProtocol?
        private var lastSize: CGSize?
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            stopObserving()
            lastSize = nil
            guard let window else { return }
            observer = NotificationCenter.default.addObserver(forName: NSWindow.didResizeNotification, object: window, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.publishSize() }
            }
            publishSize()
        }
        func stopObserving() {
            if let observer { NotificationCenter.default.removeObserver(observer) }
            observer = nil
        }
        func publishSize() {
            guard let window else { return }
            let size = window.frame.size
            guard size != lastSize else { return }
            lastSize = size
            DispatchQueue.main.async { [weak self, weak window] in
                guard let self, let window, self.window === window else { return }
                self.changed?(size)
            }
        }
    }
}

enum Theme {
    static let dialogTitleFont = Font.reference(size: 22, weight: .semibold)
    // Match the Windows dialog body size now that Segoe UI is available.
    static let dialogBodyFont = Font.reference(size: 14)
    static let primaryText = Color(hex: "#F2F1F5")
    static let canvas = Color(hex: "#141519")
    static let background = LinearGradient(colors: [Color(hex: "#1B1C20"), Color(hex: "#141519")], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let card = Color(hex: "#1C1E24")
    static let border = Color(hex: "#383B46")
    static let control = Color(hex: "#232429")
    static let activeControl = Color(hex: "#483A64")
    static let accent = Color(hex: "#C3ADF8")
    static let actionAccent = Color(hex: "#B5A0F4")
    static let dialogBackground = Color(hex: "#222329")
    static let dialogText = Color(hex: "#BEC1D2")
    static let secondary = Color(hex: "#B6B8C8")
    static let amber = Color(hex: "#EAAA51")
    static let palette = ["#B99AF8", "#CDEB82", "#58A6FF", "#D587A5", "#55C9BD", "#F2C94C", "#F05B69"]
    static func colors(_ state: CapacityState) -> [Color] {
        switch state {
        case .healthy: [Color(hex: "#208455"), Color(hex: "#4DCE8A")]
        case .info: [Color(hex: "#2367B5"), Color(hex: "#58A6FF")]
        case .low: [Color(hex: "#AE8519"), Color(hex: "#F2C94C")]
        case .critical, .exhausted: [Color(hex: "#B52D42"), Color(hex: "#F05B69")]
        case .unknown: [Color(hex: "#353641"), Color(hex: "#45464D")]
        }
    }
}

struct ReferencePanelSurface: ViewModifier {
    func body(content: Content) -> some View {
        content.foregroundStyle(Theme.primaryText)
            .background(Theme.canvas)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color(hex: "#65577F"), lineWidth: 1)
                    .allowsHitTesting(false)
            }
            .presentationCornerRadius(16)
    }
}
extension View {
    func referencePanelSurface() -> some View { modifier(ReferencePanelSurface()) }
}
extension Color {
    init(hex: String) {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
        self.init(red: Double((value >> 16) & 255) / 255, green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255)
    }
    var hex: String {
        guard let rgb = NSColor(self).usingColorSpace(.sRGB) else { return "#B5A0F4" }
        return String(format: "#%02X%02X%02X", Int((rgb.redComponent * 255).rounded()), Int((rgb.greenComponent * 255).rounded()), Int((rgb.blueComponent * 255).rounded()))
    }
}
private struct ActionForegroundKey: EnvironmentKey {
    static let defaultValue: Color = Theme.actionAccent
}
extension EnvironmentValues {
    var actionForeground: Color {
        get { self[ActionForegroundKey.self] }
        set { self[ActionForegroundKey.self] = newValue }
    }
}
struct ScroogeButtonStyle: ButtonStyle {
    var selected = false
    var processing = false
    var segmented = false
    var horizontalPadding: CGFloat = 16
    func makeBody(configuration: Configuration) -> some View {
        Surface(configuration: configuration, selected: selected, processing: processing, segmented: segmented, horizontalPadding: horizontalPadding)
    }
    private struct Surface: View {
        let configuration: ButtonStyleConfiguration
        let selected: Bool
        let processing: Bool
        let segmented: Bool
        let horizontalPadding: CGFloat
        @Environment(\.isEnabled) private var enabled
        @State private var hovered = false
        private var interacting: Bool { processing || (enabled && (hovered || configuration.isPressed)) }
        private var highlighted: Bool { selected || interacting }
        var body: some View {
            configuration.label
                .font(.reference(size: 14))
                .foregroundStyle(interacting ? Color.white : Color(hex: "#F2F1F5"))
                .environment(\.actionForeground, interacting ? .white : Theme.actionAccent)
                .padding(.horizontal, segmented ? 0 : horizontalPadding)
                .frame(minHeight: 44)
                .background(highlighted ? Theme.activeControl : Theme.control)
                .clipShape(RoundedRectangle(cornerRadius: segmented ? 0 : 10))
                .overlay {
                    if !segmented { RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#45464D")) }
                }
                .onHover { hovered = $0 }
        }
    }
}
struct ActionLabel: View {
    let title: String
    let symbol: String
    var body: some View { HStack(spacing: 9) { ActionIcon(symbol: symbol, size: 20); if !title.isEmpty { Text(title) } } }
}
struct ScroogeCard<Content: View>: View {
    var inset: CGFloat = 20
    @ViewBuilder var content: Content
    var body: some View { content.padding(inset).background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Theme.border)) }
}

/// Settings use the reference's persistent lavender indicator while SwiftUI keeps
/// ownership of wheel, trackpad, keyboard and momentum scrolling.
struct SettingsScrollView<Content: View>: View {
    @ViewBuilder var content: Content
    @State private var position = ScrollPosition(y: 0)
    @State private var metrics = Metrics()
    @State private var dragStart: CGFloat?

    private struct Metrics: Equatable {
        var offset: CGFloat = 0
        var contentHeight: CGFloat = 0
        var viewportHeight: CGFloat = 0
        var maximumOffset: CGFloat { max(0, contentHeight - viewportHeight) }
    }

    var body: some View {
        ScrollView { content }
            .scrollPosition($position)
            .scrollIndicators(.hidden)
            .onScrollGeometryChange(for: Metrics.self) { geometry in
                Metrics(offset: geometry.contentOffset.y + geometry.contentInsets.top,
                        contentHeight: geometry.contentSize.height + geometry.contentInsets.top + geometry.contentInsets.bottom,
                        viewportHeight: geometry.containerSize.height)
            } action: { _, next in metrics = next }
            .overlay(alignment: .trailing) {
                if metrics.maximumOffset > 0 {
                    GeometryReader { geometry in
                        let height = geometry.size.height
                        let thumbHeight = min(height, max(30, height * metrics.viewportHeight / max(1, metrics.contentHeight)))
                        let travel = max(0, height - thumbHeight)
                        let offset = min(metrics.maximumOffset, max(0, metrics.offset))
                        let thumbTop = travel * offset / metrics.maximumOffset
                        Color.clear.contentShape(Rectangle())
                            .onTapGesture { location in
                                scroll(to: offset + (location.y < thumbTop ? -1 : 1) * metrics.viewportHeight)
                            }
                            .accessibilityHidden(true)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "#B197F2"))
                            .frame(width: 8, height: thumbHeight)
                            .frame(width: 14)
                            .contentShape(Rectangle())
                            .offset(y: thumbTop)
                            .gesture(DragGesture(minimumDistance: 0).onChanged { event in
                                if dragStart == nil { dragStart = offset }
                                guard travel > 0 else { return }
                                scroll(to: (dragStart ?? offset) + event.translation.height / travel * metrics.maximumOffset)
                            }.onEnded { _ in dragStart = nil })
                            .accessibilityLabel("Settings Scroll Position")
                            .accessibilityValue("\(Int((offset / metrics.maximumOffset * 100).rounded())) percent")
                            .accessibilityAdjustableAction { direction in
                                scroll(to: offset + (direction == .increment ? 1 : -1) * metrics.viewportHeight * 0.9)
                            }
                    }.frame(width: 14)
                }
            }
    }

    private func scroll(to offset: CGFloat) {
        position.scrollTo(y: min(metrics.maximumOffset, max(0, offset)))
    }
}
/// Bundle assets are immutable; decoding SVGs during each scroll frame is unnecessary.
@MainActor private enum ThemeImages {
    private static var images: [String: NSImage] = [:]
    private static var missing: Set<String> = []
    static func image(_ name: String, extension ext: String) -> NSImage? {
        let key = name + "." + ext
        if let image = images[key] { return image }
        guard !missing.contains(key) else { return nil }
        guard let url = Bundle.main.url(forResource: name, withExtension: ext), let image = NSImage(contentsOf: url) else {
            missing.insert(key); return nil
        }
        images[key] = image
        return image
    }
}

struct ProviderIcon: View {
    let provider: Provider
    var size: CGFloat = 40
    var body: some View {
        Group {
            if let image = ThemeImages.image(provider.imageName, extension: "png") {
                Image(nsImage: image).resizable().scaledToFit()
            } else if let image = ThemeImages.image(provider.imageName, extension: "svg") {
                Image(nsImage: image).resizable().scaledToFit()
            } else { Text(provider == .claude ? "✳" : provider == .copilot ? "◉" : "◎").font(.reference(size: size)) }
        }.frame(width: size, height: size).accessibilityLabel(provider.rawValue)
    }
}


struct ActionIcon: View {
    @Environment(\.actionForeground) private var foreground
    let symbol: String
    var size: CGFloat = 19
    private var referenceGlyph: String? {
        switch symbol {
        case "gearshape": "\u{E713}"
        case "arrow.clockwise": "\u{E72C}"
        case "clock": "\u{E823}"
        case "clock.arrow.circlepath": "\u{E81C}"
        case "person": "\u{E77B}"
        case "play": "\u{E768}"
        case "folder": "\u{E8B7}"
        case "desktopcomputer": "\u{E7F4}"
        case "plus": "\u{E710}"
        case "trash": "\u{E74D}"
        case "xmark": "\u{E711}"
        case "moon": "\u{E708}"
        case "speaker.wave.2": "\u{E767}"
        case "globe": "\u{E909}"
        case "slider.horizontal.3": "\u{E9E9}"
        case "link": "\u{E71B}"
        case "info.circle": "\u{E946}"
        case "arrow.up.right.square": "\u{E8A7}"
        case "key": "\u{E8D7}"
        default: nil
        }
    }
    private var resource: String? {
        switch symbol {
        case "bell.badge": "alarm_on"
        case "bell.slash": "alarm_off"
        default: nil
        }
    }
    var body: some View {
        Group {
            if let referenceGlyph {
                Text(referenceGlyph).font(ReferenceTypography.iconFont(size: size))
                    .foregroundStyle(foreground)
            } else if symbol == "circle.grid.3x3.fill" {
                Canvas { context, _ in
                    for row in 0..<3 {
                        for column in 0..<2 {
                            // WinUI strokes the 5-point ellipse inside its bounds.
                            let bounds = CGRect(x: 3.75 + Double(column) * 9,
                                                y: 1.75 + Double(row) * 7.5, width: 3.5, height: 3.5)
                            context.stroke(Path(ellipseIn: bounds), with: .color(foreground), lineWidth: 1.5)
                        }
                    }
                }.frame(width: 20, height: 22)
            } else if symbol == "account.reorder" {
                Canvas { context, _ in
                    for row in 0..<3 {
                        for column in 0..<2 {
                            let bounds = CGRect(x: 3 + Double(column) * 5,
                                                y: 2 + Double(row) * 5, width: 3, height: 3)
                            context.fill(Path(ellipseIn: bounds), with: .color(foreground))
                        }
                    }
                }.frame(width: 14, height: 17)
            } else if symbol == "battery.100percent" || symbol == "battery.25percent" {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).strokeBorder(foreground, lineWidth: 1.5).frame(height: 14)
                    RoundedRectangle(cornerRadius: 1).fill(foreground)
                        .frame(width: symbol == "battery.25percent" ? 14 : 4, height: 7)
                        .padding(.leading, 4)
                }.frame(width: 22, height: 20)
            } else if let resource, let image = ThemeImages.image(resource, extension: "svg") {
                Image(nsImage: image).renderingMode(.template).resizable().scaledToFit().foregroundStyle(foreground)
            } else { Image(systemName: symbol).font(.reference(size: size)).foregroundStyle(foreground) }
        }.frame(width: size, height: size).accessibilityHidden(true)
    }
}

/// Matches the reference switch geometry while retaining Toggle accessibility.
struct ScroogeSwitchStyle: ToggleStyle {
    var showsLabel = true
    var onColor = Color(hex: "#8170CF")
    var thumbColor: Color? = nil
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            if showsLabel {
                configuration.label
                Spacer(minLength: 12)
            }
            Button { configuration.isOn.toggle() } label: {
                Capsule().fill(configuration.isOn ? onColor : Theme.control)
                    .overlay(Capsule().stroke(configuration.isOn ? Color.clear : Theme.secondary, lineWidth: 1))
                    .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                        Circle().fill(thumbColor ?? (configuration.isOn ? Color(hex: "#141519") : Theme.secondary))
                            .frame(width: 12, height: 12).padding(4)
                    }
                    .frame(width: 40, height: 20)
            }
            .buttonStyle(.plain)
        }
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }.toggleStyle(.switch)
        }
    }
}

struct ScroogePercentSlider: View {
    @Binding var value: Double
    var color: Color = Theme.accent
    var thumbColor: Color? = nil
    var roundsValue = true
    @FocusState private var focused: Bool
    var body: some View {
        GeometryReader { geometry in
            let span = max(0, geometry.size.width - 20)
            let x = 10 + span * min(100, max(0, value)) / 100
            Canvas { context, size in
                let y = size.height / 2
                func rail(_ width: CGFloat, _ color: Color) {
                    context.fill(Path(roundedRect: CGRect(x: 0, y: y - 2, width: width, height: 4), cornerRadius: 2), with: .color(color))
                }
                // WinUI extends the rail to the control edges; only thumb travel is inset.
                rail(size.width, Color(hex: "#41434F"))
                rail(x, color)
                context.fill(Path(ellipseIn: CGRect(x: x - 10, y: y - 10, width: 20, height: 20)), with: .color(Color(hex: "#41434F")))
                context.fill(Path(ellipseIn: CGRect(x: x - 5, y: y - 5, width: 10, height: 10)), with: .color(thumbColor ?? color))
                if focused {
                    context.stroke(Path(ellipseIn: CGRect(x: x - 13, y: y - 13, width: 26, height: 26)), with: .color(Theme.accent), lineWidth: 1)
                }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { event in
                focused = true
                guard span > 0 else { return }
                setValue((event.location.x - 10) / span * 100)
            })
        }.frame(height: 32)
        .focusable().focused($focused).focusEffectDisabled()
        .onKeyPress(keys: [.leftArrow, .downArrow, .rightArrow, .upArrow]) { press in
            setValue(value + (press.key == .leftArrow || press.key == .downArrow ? -1 : 1)); return .handled
        }
        .onKeyPress(.home) { setValue(0); return .handled }
        .onKeyPress(.end) { setValue(100); return .handled }
        .accessibilityValue("\(Int(value.rounded(.toNearestOrEven)))%")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: setValue(value + 1)
            case .decrement: setValue(value - 1)
            @unknown default: break
            }
        }
    }
    private func setValue(_ proposed: Double) {
        let next = min(100, max(0, roundsValue ? proposed.rounded(.toNearestOrEven) : proposed))
        if value != next { value = next }
    }
}

struct ThresholdReadoutIcon: View {
    let severity: ReminderSeverity
    var body: some View {
        if severity == .info {
            Text("\u{E946}").font(ReferenceTypography.iconFont(size: 18)).accessibilityLabel("Information").foregroundStyle(Color(hex: "#58A6FF")).frame(width: 18, height: 18)
        } else if let image = ThemeImages.image(severity == .warning ? "threshold_warning" : "threshold_critical", extension: "svg") {
            Image(nsImage: image).resizable().scaledToFit().frame(width: 18, height: 18)
        }
    }
}

/// Immediate, noninteractive reference tooltip; owner geometry changes dismiss it.
struct ImmediateReferenceTooltip: ViewModifier {
    let text: String
    @State private var visible = false
    func body(content: Content) -> some View {
        content
            .onHover { visible = $0 }
            .simultaneousGesture(TapGesture().onEnded { visible = false })
            .accessibilityHint(text)
            .background {
                GeometryReader { geometry in
                    HistoryPointerTracking(plainText: true, text: visible ? text : nil, pinned: true,
                                           anchor: CGPoint(x: geometry.size.width / 2, y: 0), onMove: { point in if point == nil { visible = false } })
                }
            }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { _ in visible = false }
            .onDisappear { visible = false }
    }
}

/// Refresh the remaining-time label when the pointer opens the tooltip.
struct ImmediateResetTooltip: ViewModifier {
    let context: String
    let date: Date
    let zone: TimeZone
    let accessibilityText: String
    var referenceDate: Date? = nil
    @State private var visible = false
    @State private var openedAt = Date.now
    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                if hovering { openedAt = referenceDate ?? .now }
                visible = hovering
            }
            .simultaneousGesture(TapGesture().onEnded { visible = false })
            .accessibilityHint(accessibilityText)
            .background {
                GeometryReader { geometry in
                    HistoryPointerTracking(plainText: true,
                        resetContent: ResetTooltipContent(context: context, date: date, now: openedAt, zone: zone),
                        text: visible ? context : nil, pinned: true,
                        anchor: CGPoint(x: geometry.size.width / 2, y: 0),
                        onMove: { point in if point == nil { visible = false } })
                }
            }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { _ in visible = false }
            .onDisappear { visible = false }
    }
}

import SwiftUI

extension EnvironmentValues {
    @Entry var dashboardHostSize: CGSize? = nil
}

enum Theme {
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
                .font(.system(size: 14))
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
            } else { Text(provider == .claude ? "✳" : provider == .copilot ? "◉" : "◎").font(.system(size: size)) }
        }.frame(width: size, height: size).accessibilityLabel(provider.rawValue)
    }
}


struct ActionIcon: View {
    @Environment(\.actionForeground) private var foreground
    let symbol: String
    var size: CGFloat = 19
    private var resource: String? {
        switch symbol {
        case "gearshape": "settings"
        case "arrow.clockwise": "refresh"
        case "bell.badge": "alarm_on"
        case "bell.slash": "alarm_off"
        default: nil
        }
    }
    var body: some View {
        Group {
            if symbol == "circle.grid.3x3.fill" {
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
            } else if symbol == "clock.arrow.circlepath" {
                Canvas { context, _ in
                    context.scaleBy(x: size / 30, y: size / 30)
                    var path = Path()
                    path.addArc(center: CGPoint(x: 15, y: 15), radius: 13,
                                startAngle: .degrees(180), endAngle: .degrees(225), clockwise: true)
                    path.move(to: CGPoint(x: 2, y: 2))
                    path.addLine(to: CGPoint(x: 2, y: 9))
                    path.addLine(to: CGPoint(x: 9, y: 9))
                    path.move(to: CGPoint(x: 15, y: 6))
                    path.addLine(to: CGPoint(x: 15, y: 15))
                    path.addLine(to: CGPoint(x: 21, y: 15))
                    context.stroke(path, with: .color(foreground),
                                   style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                }.frame(width: size, height: size)
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
            } else if symbol == "plus" || symbol == "trash" {
                Canvas { context, _ in
                    context.scaleBy(x: size / 20, y: size / 20)
                    var path = Path()
                    if symbol == "plus" {
                        path.move(to: CGPoint(x: 2, y: 10))
                        path.addLine(to: CGPoint(x: 18, y: 10))
                        path.move(to: CGPoint(x: 10, y: 2))
                        path.addLine(to: CGPoint(x: 10, y: 18))
                    } else {
                        path.move(to: CGPoint(x: 3, y: 4))
                        path.addLine(to: CGPoint(x: 17, y: 4))
                        path.move(to: CGPoint(x: 7, y: 4))
                        path.addLine(to: CGPoint(x: 7, y: 1))
                        path.addLine(to: CGPoint(x: 13, y: 1))
                        path.addLine(to: CGPoint(x: 13, y: 4))
                        path.move(to: CGPoint(x: 4, y: 4))
                        path.addLine(to: CGPoint(x: 5, y: 19))
                        path.addLine(to: CGPoint(x: 15, y: 19))
                        path.addLine(to: CGPoint(x: 16, y: 4))
                        for x in [8.0, 12.0] {
                            path.move(to: CGPoint(x: x, y: 7))
                            path.addLine(to: CGPoint(x: x, y: 16))
                        }
                    }
                    context.stroke(path, with: .color(foreground), lineWidth: 1)
                }
            } else if symbol == "person" {
                Canvas { context, _ in
                    context.scaleBy(x: size / 20, y: size / 20)
                    context.stroke(Path(ellipseIn: CGRect(x: 6, y: 0.5, width: 8, height: 8)),
                                   with: .color(foreground), lineWidth: 1)
                    // The reference uses a shallow rounded shoulder panel, not a semicircle.
                    var shoulders = Path()
                    shoulders.move(to: CGPoint(x: 5, y: 11))
                    shoulders.addLine(to: CGPoint(x: 15, y: 11))
                    shoulders.addQuadCurve(to: CGPoint(x: 18, y: 14), control: CGPoint(x: 18, y: 11))
                    shoulders.addLine(to: CGPoint(x: 18, y: 16))
                    shoulders.addQuadCurve(to: CGPoint(x: 10, y: 19.5), control: CGPoint(x: 18, y: 19.5))
                    shoulders.addQuadCurve(to: CGPoint(x: 2, y: 16), control: CGPoint(x: 2, y: 19.5))
                    shoulders.addLine(to: CGPoint(x: 2, y: 14))
                    shoulders.addQuadCurve(to: CGPoint(x: 5, y: 11), control: CGPoint(x: 2, y: 11))
                    context.stroke(shoulders, with: .color(foreground), lineWidth: 1)
                }
            } else if symbol == "desktopcomputer" {
                Canvas { context, _ in
                    context.scaleBy(x: size / 20, y: size / 20)
                    let screen = Path(roundedRect: CGRect(x: 0.5, y: 1.5, width: 19, height: 14),
                                      cornerRadius: 1)
                    context.stroke(screen, with: .color(foreground), lineWidth: 1)
                    var stand = Path()
                    stand.move(to: CGPoint(x: 8, y: 15.5))
                    stand.addLine(to: CGPoint(x: 8, y: 19))
                    stand.move(to: CGPoint(x: 12, y: 15.5))
                    stand.addLine(to: CGPoint(x: 12, y: 19))
                    stand.move(to: CGPoint(x: 5, y: 19))
                    stand.addLine(to: CGPoint(x: 15, y: 19))
                    context.stroke(stand, with: .color(foreground), lineWidth: 1)
                }
            } else if let resource, let image = ThemeImages.image(resource, extension: "svg") {
                Image(nsImage: image).renderingMode(.template).resizable().scaledToFit().foregroundStyle(foreground)
            } else { Image(systemName: symbol).font(.system(size: size)).foregroundStyle(foreground) }
        }.frame(width: size, height: size).accessibilityHidden(true)
    }
}

/// Matches the reference switch geometry while retaining Toggle accessibility.
struct ScroogeSwitchStyle: ToggleStyle {
    var showsLabel = true
    var onColor = Color(hex: "#8973DB")
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
    @FocusState private var focused: Bool
    var body: some View {
        GeometryReader { geometry in
            let span = max(0, geometry.size.width - 20)
            let x = 10 + span * min(100, max(0, value)) / 100
            Canvas { context, size in
                let y = size.height / 2
                func rail(_ width: CGFloat, _ color: Color) {
                    context.fill(Path(roundedRect: CGRect(x: 10, y: y - 2, width: width, height: 4), cornerRadius: 2), with: .color(color))
                }
                rail(span, Color(hex: "#41434F"))
                rail(max(0, x - 10), color)
                context.fill(Path(ellipseIn: CGRect(x: x - 10, y: y - 10, width: 20, height: 20)), with: .color(Color(hex: "#41434F")))
                context.fill(Path(ellipseIn: CGRect(x: x - 5, y: y - 5, width: 10, height: 10)), with: .color(color))
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
        .accessibilityValue("\(Int(value))%")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: setValue(value + 1)
            case .decrement: setValue(value - 1)
            @unknown default: break
            }
        }
    }
    private func setValue(_ proposed: Double) {
        let next = min(100, max(0, proposed.rounded()))
        if value != next { value = next }
    }
}

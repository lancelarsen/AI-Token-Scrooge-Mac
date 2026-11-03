import SwiftUI

enum Theme {
    static let background = LinearGradient(colors: [Color(hex: "#1B1C20"), Color(hex: "#141519")], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let card = Color(hex: "#1C1E24")
    static let border = Color(hex: "#383B46")
    static let control = Color(hex: "#232429")
    static let accent = Color(hex: "#C3ADF8")
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
        guard let rgb = NSColor(self).usingColorSpace(.deviceRGB) else { return "#B5A0F4" }
        return String(format: "#%02X%02X%02X", Int(rgb.redComponent * 255), Int(rgb.greenComponent * 255), Int(rgb.blueComponent * 255))
    }
}
struct ScroogeButtonStyle: ButtonStyle {
    var selected = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 12)).padding(.horizontal, 16).frame(minHeight: 44)
            .background(selected ? Theme.accent.opacity(0.28) : Theme.control)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#45464D")))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
struct ActionLabel: View {
    let title: String
    let symbol: String
    var body: some View { HStack(spacing: 10) { ActionIcon(symbol: symbol, size: 19); if !title.isEmpty { Text(title) } } }
}
struct ScroogeCard<Content: View>: View {
    var inset: CGFloat = 20
    @ViewBuilder var content: Content
    var body: some View { content.padding(inset).background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Theme.border)) }
}
struct ProviderIcon: View {
    let provider: Provider
    var size: CGFloat = 40
    var body: some View {
        Group {
            if let url = Bundle.main.url(forResource: provider.imageName, withExtension: "png"), let image = NSImage(contentsOf: url) {
                Image(nsImage: image).resizable().scaledToFit()
            } else if let url = Bundle.main.url(forResource: provider.imageName, withExtension: "svg"), let image = NSImage(contentsOf: url) {
                Image(nsImage: image).resizable().scaledToFit()
            } else { Text(provider == .claude ? "✳" : provider == .copilot ? "◉" : "◎").font(.system(size: size)) }
        }.frame(width: size, height: size).accessibilityLabel(provider.rawValue)
    }
}


struct ActionIcon: View {
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
                VStack(spacing: size * 0.12) {
                    ForEach(0..<3) { _ in
                        HStack(spacing: size * 0.18) {
                            ForEach(0..<2) { _ in Circle().stroke(Theme.accent, lineWidth: 1.2).frame(width: size * 0.22, height: size * 0.22) }
                        }
                    }
                }
            } else if symbol == "battery.100percent" || symbol == "battery.25percent" {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).stroke(Theme.accent, lineWidth: 1.5).frame(height: size * 0.64)
                    RoundedRectangle(cornerRadius: 1).fill(Theme.accent)
                        .frame(width: symbol == "battery.25percent" ? size * 0.64 : size * 0.18, height: size * 0.32)
                        .padding(.leading, size * 0.18)
                }
            } else if let resource, let url = Bundle.main.url(forResource: resource, withExtension: "svg"), let image = NSImage(contentsOf: url) {
                Image(nsImage: image).resizable().scaledToFit()
            } else { Image(systemName: symbol).font(.system(size: size)).foregroundStyle(Theme.accent) }
        }.frame(width: size, height: size).accessibilityHidden(true)
    }
}

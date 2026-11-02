import SwiftUI

struct AlertBannerView: View {
    let alert: AlertEvent
    @Environment(AppStore.self) private var store
    private var provider: Provider? { store.state.accounts.first { $0.id == alert.accountID }?.provider }
    private var severityColor: Color {
        switch alert.severity {
        case .critical: Color(hex: "#F05B69")
        case .warning: Color(hex: "#F2C94C")
        case .info: Color(hex: "#58A6FF")
        case nil: Theme.accent
        }
    }
    var body: some View {
        Group {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    if let provider { ProviderIcon(provider: provider, size: 38) }
                    else if let url = Bundle.main.url(forResource: "token_baron", withExtension: "png"), let image = NSImage(contentsOf: url) {
                        Image(nsImage: image).resizable().scaledToFit().frame(width: 38, height: 38).accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(provider == .codex ? "OpenAI Codex" : provider?.rawValue ?? "Scrooge")
                            .font(.system(size: 12)).foregroundStyle(Theme.accent)
                        Text(alert.title).font(.system(size: 15, weight: .semibold)).foregroundStyle(severityColor)
                    }
                }
                Text(store.state.settings.privacy ? "Account Details Hidden" : alert.detail).foregroundStyle(Theme.secondary)
                HStack {
                    Button("Show Info") {
                        store.showAlertAccount(alert)
                        store.activeAlert = nil
                        SoundPlayer.shared.play(settings: store.state.settings, cue: "info")
                    }
                    Button("Snooze 1 Hour") { store.snooze(alert.id, minutes: 60) }
                    Button("Dismiss") { store.dismissAlert(alert.id) }
                }.buttonStyle(ScroogeButtonStyle())
            }
        }.padding(18).frame(maxWidth: 520, alignment: .leading)
            .background(Color(hex: "#222329"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(severityColor))
            .shadow(radius: 16).padding(20)
    }
}

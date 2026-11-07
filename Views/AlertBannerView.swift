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
        AlertBannerSizing {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    if let provider { ProviderIcon(provider: provider, size: 38) }
                    else if let image = ThemeImages.image("token_baron", extension: "png") {
                        Image(nsImage: image).resizable().scaledToFit().frame(width: 38, height: 38).accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(provider == .codex ? "OpenAI Codex" : provider?.rawValue ?? "Scrooge")
                            .font(.reference(size: 12)).foregroundStyle(Theme.accent)
                        Text(alert.title).font(.reference(size: 15, weight: .semibold)).foregroundStyle(severityColor)
                            .referenceFallbackLineMetrics(size: 15)
                    }
                }
                Text(store.state.settings.privacy ? "Account Details Hidden" : alert.detail).font(.reference(size: 12)).foregroundStyle(Theme.secondary)
                HStack(spacing: 8) {
                    Button {
                        store.showAlertAccount(alert)
                        store.activeAlert = nil
                        SoundPlayer.shared.play(settings: store.state.settings, cue: "info")
                    } label: { DialogActionLabel(title: "Show Info") }
                    Button { store.snooze(alert.id, minutes: 60) } label: { DialogActionLabel(title: "Snooze 1 Hour") }
                    Button { store.dismissAlert(alert.id) } label: { DialogActionLabel(title: "Dismiss") }
                }.buttonStyle(ScroogeButtonStyle())
            }
            .padding(18)
        }
        .background(Color(hex: "#222329"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(severityColor))
        .padding(20)
    }
}

/// Measure wrapped messages at the final width before allocating their height.
/// Capping an unconstrained ideal size keeps the short banner height even when
/// its title or detail needs more lines.
private struct AlertBannerSizing: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let content = subviews.first else { return .zero }
        let width = min(520, content.sizeThatFits(.unspecified).width)
        let fitted = content.sizeThatFits(.init(width: width, height: nil))
        return CGSize(width: width, height: fitted.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, anchor: .topLeading,
                             proposal: .init(width: bounds.width, height: bounds.height))
    }
}

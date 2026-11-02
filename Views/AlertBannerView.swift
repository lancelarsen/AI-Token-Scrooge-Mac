import SwiftUI

struct AlertBannerView: View {
    let alert: AlertEvent
    @Environment(AppStore.self) private var store
    var body: some View {
        ScroogeCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(alert.title).font(.headline).foregroundStyle(Theme.accent)
                Text(store.state.settings.privacy ? "Account Details Hidden" : alert.detail).foregroundStyle(Theme.secondary)
                HStack {
                    Button("Show Info") {
                        store.selectedAccount = store.state.accounts.first { $0.id == alert.accountID }
                        store.activeAlert = nil
                        SoundPlayer.shared.play(settings: store.state.settings, cue: "info")
                    }
                    Button("Snooze 1 Hour") { store.snooze(alert.id, minutes: 60) }
                    Button("Dismiss") { store.dismissAlert(alert.id) }
                }.buttonStyle(ScroogeButtonStyle())
            }
        }.frame(maxWidth: 520).shadow(radius: 16).padding(20)
    }
}

import SwiftUI

struct AlertHistoryView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack { Text("Alert History").font(.title2).foregroundStyle(Theme.accent); Spacer(); Button("Close") { dismiss() } }
            if store.state.alerts.isEmpty { Text("No Alerts Yet").foregroundStyle(Theme.secondary); Spacer() }
            else {
                ScrollView {
                    ForEach(store.state.alerts.sorted { $0.createdAt > $1.createdAt }) { alert in
                        ScroogeCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(alert.title).font(.headline)
                                Text(store.state.settings.privacy ? "Account Details Hidden" : alert.detail).foregroundStyle(Theme.secondary)
                                Text(Format.date(alert.createdAt, zone: store.state.settings.zone)).font(.caption)
                                HStack {
                                    Menu("Snooze") { ForEach([15,30,60,120], id: \.self) { minutes in Button("\(minutes) Minutes") { store.snooze(alert.id, minutes: minutes) } } }
                                    Button("Dismiss") { store.dismissAlert(alert.id) }
                                }.disabled(alert.dismissed)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }.padding(24).frame(width: 650, height: 600).background(Theme.background).preferredColorScheme(.dark)
    }
}

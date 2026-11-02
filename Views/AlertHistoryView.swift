import SwiftUI

struct AlertHistoryView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAlert: AlertEvent?
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack { Text("Alert History").font(.title2).foregroundStyle(Theme.accent); Spacer(); Button("Close") { dismiss() } }
            if store.state.alerts.isEmpty { Text("No Alerts Yet").foregroundStyle(Theme.secondary); Spacer() }
            else {
                ScrollView {
                    ForEach(store.state.alerts.sorted { $0.createdAt > $1.createdAt }) { alert in
                        ScroogeCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Button { selectedAlert = alert } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(alert.title).font(.headline)
                                        Text(store.state.settings.privacy ? "Account Details Hidden" : alert.detail).foregroundStyle(Theme.secondary)
                                        Text(Format.date(alert.createdAt, zone: store.state.settings.zone)).font(.caption)
                                        Text(alert.delivered ? "Sent to macOS" : "Recorded in History").font(.caption).foregroundStyle(Theme.secondary)
                                    }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                                }.buttonStyle(.plain).help("Show Usage Details")
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
        .sheet(item: $selectedAlert) { alert in
            VStack(alignment: .leading, spacing: 16) {
                ScrollView {
                    if let account = store.state.accounts.first(where: { $0.id == alert.accountID }),
                       let snapshot = store.state.snapshots[account.id], snapshot.belongs(to: account) {
                        if alert.windowID == nil, let reserve = snapshot.reserve {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Available Resets").font(.title2)
                                Text(store.state.settings.privacy ? "Account Details Hidden" : "\(account.provider.rawValue) / \(account.nickname)")
                                Text("\(reserve.availableCount.map(String.init) ?? "Unknown") Reported Available")
                                Text("Snapshot Fetched: \(Format.date(snapshot.observedAt, zone: store.state.settings.zone))")
                                Text(account.enabled ? snapshot.health.rawValue : "Monitoring Paused")
                                if reserve.hasPartialDetails { Text("Provider supplied only partial credit details.") }
                                if let credits = reserve.credits {
                                    ForEach(credits) { credit in
                                        Text("\(Format.date(credit.expiresAt, zone: store.state.settings.zone)) · \(credit.expiresAt.map { $0 <= Date() } == true ? "Expired Locally — Checking Provider" : credit.status)")
                                    }
                                } else { Text("Credit Details Unavailable") }
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        } else if let window = snapshot.windows.first(where: { alert.windowID == nil || $0.id == alert.windowID }) {
                            QuotaDetailsView(account: account, window: window, snapshot: snapshot)
                        } else { unavailableDetails }
                    } else { unavailableDetails }
                }
                Button("Close") { selectedAlert = nil }.buttonStyle(ScroogeButtonStyle())
            }.padding(24).frame(width: 500, height: 470).background(Theme.card).preferredColorScheme(.dark)
        }
    }
    private var unavailableDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Usage Details Unavailable").font(.title2)
            Text("This account or quota window is no longer available. Refresh the dashboard to check current connections.")
        }
    }
}

import SwiftUI

struct AlertHistoryView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAlert: AlertEvent?
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack { Text("Alert History").font(.system(size: 26, weight: .semibold)); Spacer(); Button { dismiss() } label: { DialogActionLabel(title: "Close", symbol: "xmark") }.buttonStyle(ScroogeButtonStyle()).keyboardShortcut(.cancelAction) }
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
            DetailsDialog(close: { selectedAlert = nil }) {
                AccountUsageDetailsView(accountID: alert.accountID, windowID: alert.windowID)
            }
        }
    }
}

struct AccountUsageDetailsView: View {
    @Environment(AppStore.self) private var store
    let accountID: String
    let windowID: String?
    var body: some View {
        if let account = store.state.accounts.first(where: { $0.id == accountID }),
           let snapshot = store.state.snapshots[account.id], snapshot.belongs(to: account) {
            if windowID == nil, let reserve = snapshot.reserve {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Available Resets").font(.system(size: 20, weight: .semibold)).foregroundStyle(.white)
                    Text("\(account.provider.rawValue) / \(store.state.settings.privacy ? "Account" : account.nickname) · \(Format.plan(account.provider, snapshot.planType))")
                    Text("\(reserve.availableCount.map(String.init) ?? "Unknown") Reported Available")
                    DetailLine(label: "Snapshot Fetched", value: Format.date(snapshot.observedAt, zone: store.state.settings.zone))
                    Text(account.enabled ? snapshot.health.rawValue : "Monitoring Paused")
                    if reserve.hasPartialDetails { Text("Provider supplied only partial credit details.") }
                    if let credits = reserve.credits {
                        ForEach(credits) { credit in
                            Text("\(Format.date(credit.expiresAt, zone: store.state.settings.zone)) · \(credit.expiresAt.map { $0 <= Date() } == true ? "Expired Locally — Checking Provider" : credit.status)")
                        }
                    } else { Text("Credit Details Unavailable") }
                }.frame(maxWidth: .infinity, alignment: .leading)
            } else if let window = snapshot.windows.first(where: { windowID == nil || $0.id == windowID }) {
                QuotaDetailsView(account: account, window: window, snapshot: snapshot)
            } else { unavailableDetails }
        } else { unavailableDetails }
    }
    private var unavailableDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Usage Details Unavailable").font(.system(size: 20, weight: .semibold)).foregroundStyle(.white)
            Text("This account or quota window is no longer available. Refresh the dashboard to check current connections.")
        }
    }
}

/// Shared Windows-style detail dialog: content-sized body and a separate action footer.
struct DetailsDialog<Content: View>: View {
    var closeTitle = "Close"
    var primaryTitle: String? = nil
    var primaryAction: (() -> Void)? = nil
    let close: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ViewThatFits(in: .vertical) {
                content().fixedSize(horizontal: false, vertical: true)
                ScrollView { content() }
            }
            .font(.system(size: 14))
            .foregroundStyle(Theme.secondary)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            Divider()
            HStack {
                Spacer()
                if let primaryTitle, let primaryAction {
                    Button(action: primaryAction) {
                        DialogActionLabel(title: primaryTitle, symbol: "checkmark")
                    }.buttonStyle(ScroogeButtonStyle())
                }
                Button(action: close) {
                    DialogActionLabel(title: closeTitle, symbol: "xmark")
                }
                .buttonStyle(ScroogeButtonStyle())
                .keyboardShortcut(.cancelAction)
            }.padding(24)
        }
        .frame(width: 480)
        .frame(maxHeight: 560)
        .fixedSize(horizontal: false, vertical: true)
        .background(Theme.card)
        .preferredColorScheme(.dark)
    }
}

struct DetailLine: View {
    let label: String
    let value: String
    var body: some View {
        (Text(label + ": ").fontWeight(.semibold).foregroundColor(.white)
         + Text(value).foregroundColor(Theme.secondary))
    }
}

struct DialogActionLabel: View {
    let title: String
    let symbol: String
    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: symbol).font(.system(size: 20)).foregroundStyle(Theme.accent)
            Text(title).font(.system(size: 14)).foregroundStyle(.white)
        }
    }
}

struct ConfirmationDetailsDialog: View {
    let title: String
    let message: String
    let actionTitle: String
    let cancel: () -> Void
    let confirm: () -> Void
    var body: some View {
        DetailsDialog(closeTitle: "Cancel", primaryTitle: actionTitle, primaryAction: confirm, close: cancel) {
            VStack(alignment: .leading, spacing: 16) {
                Text(title).font(.system(size: 20, weight: .semibold)).foregroundStyle(.white)
                Text(message)
            }
        }
    }
}

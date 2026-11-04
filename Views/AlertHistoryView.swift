import SwiftUI

struct AlertHistoryView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAlert: AlertEvent?
    @Environment(\.dashboardHostSize) private var hostSize
    private var panelSize: CGSize {
        guard let hostSize else { return CGSize(width: 1000, height: 800) }
        return CGSize(width: min(1000, max(640, hostSize.width - 48)),
                      height: min(800, max(400, hostSize.height - 64)))
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Alert history").font(.system(size: 26, weight: .semibold))
                if store.state.alerts.isEmpty {
                    Text("No alerts yet. Low capacity and expiring resets will appear here.")
                        .font(.system(size: 14)).foregroundStyle(Theme.secondary)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(store.state.alerts.sorted { $0.createdAt > $1.createdAt }) { alert in
                            Button { selectedAlert = alert } label: {
                                HStack(spacing: 10) {
                                    ActionIcon(symbol: alert.isRefreshReminder ? "arrow.clockwise" : alert.reminderID != nil ? "folder" : alert.delivered ? "arrow.up.right.square" : "clock.arrow.circlepath")
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(Format.date(alert.createdAt, zone: store.state.settings.zone)) · \(alert.title)")
                                        Text(store.state.settings.privacy ? "Account Details Hidden" : alert.detail)
                                        Text(alert.delivered ? "Sent to macOS" : "Recorded in history")
                                    }.font(.system(size: 14)).frame(maxWidth: .infinity, alignment: .leading)
                                }.padding(.vertical, 12).frame(minHeight: 80)
                            }.buttonStyle(ScroogeButtonStyle()).help("Show Usage Details")
                            .contextMenu {
                                Menu("Snooze") { ForEach([15,30,60,120], id: \.self) { minutes in Button("\(minutes) Minutes") { store.snooze(alert.id, minutes: minutes) } } }
                                Button("Dismiss") { store.dismissAlert(alert.id) }.disabled(alert.dismissed)
                            }
                        }
                    }
                }
                Button { dismiss() } label: {
                    DialogActionLabel(title: "Close", symbol: "xmark")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.buttonStyle(ScroogeButtonStyle()).keyboardShortcut(.cancelAction)
            }.padding(28)
        }
        .frame(width: panelSize.width, height: panelSize.height)
        .background(Color(hex: "#141519")).preferredColorScheme(.dark)
        .sheet(item: $selectedAlert) { alert in
            DetailsDialog(width: alert.windowID == nil ? 332 : 342, close: { selectedAlert = nil }) {
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
                    Text("Available resets").font(.system(size: 21, weight: .semibold)).foregroundStyle(Theme.accent).frame(minHeight: 32, alignment: .leading)
                    DetailLine(label: "\(account.provider.rawValue) / \(store.state.settings.privacy ? "Account" : account.nickname) · \(Format.plan(account.provider, snapshot.planType))", value: "\(reserve.availableCount.map(String.init) ?? "Unknown") reported available")
                    Text("Snapshot fetched \(Format.snapshotDate(snapshot.observedAt, zone: store.state.settings.zone)) · \(account.enabled ? snapshot.health.rawValue.capitalized : "Monitoring paused")").frame(minHeight: 19, alignment: .leading)
                    if reserve.hasPartialDetails { Text("Provider supplied only partial credit details.").frame(minHeight: 19, alignment: .leading) }
                    if let credits = reserve.credits {
                        ForEach(credits) { credit in
                            Text("• \(Format.date(credit.expiresAt, zone: store.state.settings.zone)) · \(credit.expiresAt.map { $0 <= Date() } == true ? "Expired locally — checking provider" : credit.status)").frame(minHeight: 19, alignment: .leading)
                        }
                    } else { Text("Credit details unavailable").frame(minHeight: 19, alignment: .leading) }
                }.font(.system(size: 13)).frame(maxWidth: .infinity, alignment: .leading)
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
    var width: CGFloat = 480
    var maximumHeight: CGFloat = 560
    var closeTitle = "Close"
    var primaryTitle: String? = nil
    var primarySymbol: String = "checkmark"
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
            .foregroundStyle(Theme.dialogText)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            Rectangle().fill(Color(hex: "#3B3D47")).frame(height: 1)
            HStack {
                Spacer()
                if let primaryTitle, let primaryAction {
                    Button(action: primaryAction) {
                        DialogActionLabel(title: primaryTitle, symbol: primarySymbol)
                    }.buttonStyle(ScroogeButtonStyle())
                }
                Button(action: close) {
                    DialogActionLabel(title: closeTitle, symbol: "xmark").frame(minWidth: 104)
                }
                .buttonStyle(ScroogeButtonStyle())
                .keyboardShortcut(.cancelAction)
            }.padding(24)
        }
        .frame(width: width)
        .frame(maxHeight: maximumHeight)
        .fixedSize(horizontal: false, vertical: true)
        .background(Theme.dialogBackground)
        .preferredColorScheme(.dark)
    }
}

struct DetailLine: View {
    let label: String
    let value: String
    var body: some View {
        (Text(label + ": ").fontWeight(.semibold).foregroundColor(Color(hex: "#F2F1F5"))
         + Text(value).foregroundColor(Theme.dialogText))
            .frame(minHeight: 19, alignment: .leading)
    }
}

struct DialogActionLabel: View {
    @Environment(\.actionForeground) private var foreground
    let title: String
    let symbol: String
    var body: some View {
        HStack(spacing: 9) {
            if symbol == "xmark" {
                Canvas { context, _ in
                    var cross = Path()
                    cross.move(to: CGPoint(x: 3, y: 3))
                    cross.addLine(to: CGPoint(x: 17, y: 17))
                    cross.move(to: CGPoint(x: 17, y: 3))
                    cross.addLine(to: CGPoint(x: 3, y: 17))
                    context.stroke(cross, with: .color(foreground), lineWidth: 1)
                }.frame(width: 20, height: 20).accessibilityHidden(true)
            } else {
                Image(systemName: symbol).font(.system(size: 20)).foregroundStyle(foreground)
            }
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

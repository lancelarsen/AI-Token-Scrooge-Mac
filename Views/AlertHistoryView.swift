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
                Text("Alert History").font(.reference(size: 26, weight: .semibold))
                if store.state.alerts.isEmpty {
                    Text("No alerts yet. Low capacity and expiring resets will appear here.")
                        .font(.reference(size: 14)).foregroundStyle(Theme.secondary)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(store.state.alerts.sorted { $0.createdAt > $1.createdAt }) { alert in
                            Button { selectedAlert = alert } label: {
                                HStack(spacing: 9) {
                                    ActionIcon(symbol: alert.isRefreshReminder ? "arrow.clockwise" : alert.reminderID != nil ? "folder" : alert.delivered ? "arrow.up.right.square" : "clock.arrow.circlepath")
                                    Text("\(Format.historyDate(alert.createdAt, zone: store.state.settings.zone)) · \(alert.title)\n\(store.state.settings.privacy ? "Account Details Hidden" : alert.detail)\n\(alert.delivered ? "Sent to macOS" : "Recorded in history")")
                                        .font(Theme.dialogBodyFont)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
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
                    DialogActionLabel(title: "Close")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.buttonStyle(ScroogeButtonStyle()).keyboardShortcut(.cancelAction)
            }.padding(28)
        }
        .frame(width: panelSize.width, height: panelSize.height)
        .referencePanelSurface().preferredColorScheme(.dark)
        .sheet(item: $selectedAlert) { alert in
            AccountUsageDialog(accountID: alert.accountID, windowID: alert.windowID, close: { selectedAlert = nil })
        }
    }
}

/// Route every current-account detail entry point through the same footer actions.
struct AccountUsageDialog: View {
    @Environment(AppStore.self) private var store
    @Environment(\.openURL) private var openURL
    let accountID: String
    let windowID: String?
    let close: () -> Void

    private var usageURL: URL? {
        AccountPolicy.detailUsageURL(accountID: accountID, windowID: windowID, state: store.state, isDemo: store.isDemo)
    }
    var body: some View {
        DetailsDialog(width: usageURL == nil ? (windowID == nil ? 332 : 342) : 480,
                      primaryTitle: usageURL == nil ? nil : "Open Provider Usage",
                      primaryAction: usageURL.map { url in { openProvider(url) } }, close: close) {
            AccountUsageDetailsView(accountID: accountID, windowID: windowID)
        }
    }
    private func openProvider(_ url: URL) {
        close()
        openURL(url) { accepted in
            if !accepted {
                store.errorMessage = "Provider page unavailable. Open your provider's usage page in your browser, and check its connection status."
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
                    Text("Available Resets").font(Theme.dialogTitleFont).foregroundStyle(Theme.accent).frame(minHeight: 32, alignment: .leading)
                    DetailLine(label: "\(account.provider.rawValue) / \(store.state.settings.privacy ? "Account" : account.nickname) · \(Format.plan(account.provider, snapshot.planType))", value: "\(reserve.availableCount.map(String.init) ?? "Unknown") reported available")
                    Text("Snapshot fetched \(Format.snapshotDate(snapshot.observedAt, zone: store.state.settings.zone)) · \(account.enabled ? snapshot.health.rawValue.capitalized : "Monitoring paused")").frame(minHeight: 19, alignment: .leading)
                    if reserve.hasPartialDetails { Text("Provider supplied only partial credit details.").frame(minHeight: 19, alignment: .leading) }
                    if let credits = reserve.credits {
                        ForEach(credits) { credit in
                            Text("• \(Format.date(credit.expiresAt, zone: store.state.settings.zone)) · \(credit.expiresAt.map { $0 <= store.presentationDate } == true ? "Expired locally — checking provider" : credit.status)").frame(minHeight: 19, alignment: .leading)
                        }
                    } else { Text("Credit details unavailable").frame(minHeight: 19, alignment: .leading) }
                }.font(Theme.dialogBodyFont).frame(maxWidth: .infinity, alignment: .leading)
            } else if let window = snapshot.windows.first(where: { windowID == nil || $0.id == windowID }) {
                QuotaDetailsView(account: account, window: window, snapshot: snapshot)
            } else { unavailableDetails }
        } else { unavailableDetails }
    }
    private var unavailableDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Usage Details Unavailable").font(Theme.dialogTitleFont).foregroundStyle(Theme.accent)
            Text("This account or quota window is no longer available. Refresh the dashboard to check current connections.")
        }
    }
}

/// Shared Windows-style detail dialog: content-sized body and a separate action footer.
struct DetailsDialog<Content: View>: View {
    var width: CGFloat = 480
    var maximumHeight: CGFloat = 560
    var closeTitle = "Close"
    var tabToFooter = false
    var primaryTitle: String? = nil
    var primaryAction: (() -> Void)? = nil
    let close: () -> Void
    @ViewBuilder let content: () -> Content

    private var hasPrimaryAction: Bool { primaryTitle != nil && primaryAction != nil }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ViewThatFits(in: .vertical) {
                content().fixedSize(horizontal: false, vertical: true)
                ScrollView { content() }
            }
            .font(Theme.dialogBodyFont)
            .foregroundStyle(Theme.dialogText)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            Rectangle().fill(Color(hex: "#3B3D47")).frame(height: 1)
            HStack(spacing: 8) {
                if !hasPrimaryAction { Spacer() }
                if tabToFooter, let primaryTitle, let primaryAction {
                    EditorFooterButton(title: primaryTitle, action: primaryAction)
                    EditorFooterButton(title: closeTitle, isCancel: true, action: close)
                } else {
                    if let primaryTitle, let primaryAction {
                        Button(action: primaryAction) {
                            DialogActionLabel(title: primaryTitle)
                                .frame(maxWidth: .infinity)
                        }.buttonStyle(ScroogeButtonStyle())
                    }
                    Button(action: close) {
                        DialogActionLabel(title: closeTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ScroogeButtonStyle())
                    .frame(width: hasPrimaryAction ? nil : (width - 58) / 2)
                    .keyboardShortcut(.cancelAction)
                }
            }.padding(24)
        }
        .padding(1)
        .frame(width: width)
        .frame(maxHeight: maximumHeight)
        .fixedSize(horizontal: false, vertical: true)
        .background(Theme.dialogBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(hex: "#65577F"), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .presentationCornerRadius(16)
        .preferredColorScheme(.dark)
    }
}

/// A native action stays in the same AppKit key-view loop as the color fields.
/// SwiftUI supplies the visible label; the NSButton owns clicks, key presses and AX.
private struct EditorFooterButton: View {
    let title: String
    var isCancel = false
    let action: () -> Void
    @State private var hovered = false
    var body: some View {
        DialogActionLabel(title: title)
            .foregroundStyle(hovered ? Color.white : Theme.primaryText)
            .environment(\.actionForeground, hovered ? .white : Theme.actionAccent)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(hovered ? Theme.activeControl : Theme.control, in: RoundedRectangle(cornerRadius: 10))
            .overlay { RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#45464D")) }
            .accessibilityHidden(true)
            .overlay { KeyViewButton(title: title, isCancel: isCancel, action: action) }
            .onHover { hovered = $0 }
    }

    private struct KeyViewButton: NSViewRepresentable {
        let title: String
        let isCancel: Bool
        let action: () -> Void

        final class Control: NSButton {
            var invoke: (() -> Void)?
            override var canBecomeKeyView: Bool { isEnabled && !isHiddenOrHasHiddenAncestor }
            override var acceptsFirstResponder: Bool { isEnabled }

            @objc func invokeAction() { invoke?() }
            override func keyDown(with event: NSEvent) {
                let unmodified = event.modifierFlags.intersection([.command, .option, .shift, .control]).isEmpty
                if unmodified && [36, 49, 76].contains(event.keyCode) { // Return, Space, keypad Enter
                    if !event.isARepeat { performClick(nil) }
                } else {
                    super.keyDown(with: event)
                }
            }
            override func becomeFirstResponder() -> Bool {
                let accepted = super.becomeFirstResponder()
                needsDisplay = true
                return accepted
            }
            override func resignFirstResponder() -> Bool {
                let resigned = super.resignFirstResponder()
                needsDisplay = true
                return resigned
            }
            override func draw(_ dirtyRect: NSRect) {
                guard window?.firstResponder === self else { return }
                let ring = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 9, yRadius: 9)
                NSColor(Theme.accent).setStroke()
                ring.lineWidth = 2
                ring.stroke()
            }
        }
        func makeNSView(context: Context) -> Control {
            let button = Control(frame: .zero)
            button.setButtonType(.momentaryPushIn)
            button.isBordered = false
            button.focusRingType = .none
            button.target = button
            button.action = #selector(Control.invokeAction)
            return button
        }
        func sizeThatFits(_ proposal: ProposedViewSize, nsView: Control, context: Context) -> CGSize? {
            proposal.replacingUnspecifiedDimensions(by: CGSize(width: 104, height: 44))
        }
        func updateNSView(_ button: Control, context: Context) {
            button.title = title
            button.setAccessibilityLabel(title)
            button.invoke = action
            button.keyEquivalent = isCancel ? "\u{1b}" : ""
            button.keyEquivalentModifierMask = []
        }
    }
}

struct DetailLine: View {
    let label: String
    let value: String
    var body: some View {
        let heading = Text(label + ": ").font(ReferenceTypography.nativeTextFont(semibold: true)).foregroundColor(Theme.primaryText)
        Text("\(heading)\(Text(verbatim: value).foregroundColor(Theme.dialogText))")
            .frame(minHeight: 19, alignment: .leading)
    }
}

/// Line spacing and label emphasis shared with Windows ThemedDialogs.ShowAsync.
struct DialogMessage: View {
    let message: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(message.replacingOccurrences(of: "\r", with: "").components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Color.clear.frame(height: 6)
                } else {
                    let parsed = Format.dialogLine(line)
                    if let label = parsed.label {
                        DetailLine(label: label, value: parsed.value)
                    } else {
                        Text(parsed.value).frame(minHeight: 19, alignment: .leading)
                    }
                }
            }
        }.font(Theme.dialogBodyFont).foregroundStyle(Theme.dialogText)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DialogActionLabel: View {
    @Environment(\.actionForeground) private var foreground
    let title: String
    var body: some View {
        HStack(spacing: 9) {
            Text(Format.actionGlyph(title))
                .font(ReferenceTypography.iconFont(size: 20))
                .foregroundStyle(foreground)
                .accessibilityHidden(true)
            Text(title).font(Theme.dialogBodyFont)
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
                Text(title).font(Theme.dialogTitleFont).foregroundStyle(Theme.accent)
                DialogMessage(message: message)
            }
        }
    }
}

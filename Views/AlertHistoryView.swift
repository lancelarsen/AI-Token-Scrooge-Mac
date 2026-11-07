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
                Text("Alert History").font(.reference(size: 26, weight: .semibold)).referenceFallbackLineMetrics(size: 26)
                if store.state.alerts.isEmpty {
                    Text("No alerts yet. Low capacity and expiring resets will appear here.")
                        .font(.reference(size: 14)).foregroundStyle(Theme.secondary)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(store.state.alerts.sorted { $0.createdAt > $1.createdAt }) { alert in
                            let text = "\(Format.historyDate(alert.createdAt, zone: store.state.settings.zone)) · \(alert.title)\n\(store.state.settings.privacy ? "Account Details Hidden" : alert.detail)\n\(alert.delivered ? "Sent to macOS" : "Recorded in history")"
                            Button { selectedAlert = alert } label: {
                                DialogActionLabel(title: text)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 10).frame(minHeight: 78)
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
        .referencePanelFrame(size: panelSize).preferredColorScheme(.dark)
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
    private var title: String {
        guard let account = store.state.accounts.first(where: { $0.id == accountID }),
              let snapshot = store.state.snapshots[account.id], snapshot.belongs(to: account) else {
            return "Usage Details Unavailable"
        }
        if windowID == nil, snapshot.reserve != nil { return "Available resets" }
        guard snapshot.windows.contains(where: { windowID == nil || $0.id == windowID }) else {
            return "Usage Details Unavailable"
        }
        return "\(account.provider.rawValue) / \(store.state.settings.privacy ? "Account" : account.nickname) · \(Format.plan(account.provider, snapshot.planType))"
    }
    var body: some View {
        DetailsDialog(title: title,
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
                    DialogBodyText("\(account.provider.rawValue) / \(store.state.settings.privacy ? "Account" : account.nickname) · \(Format.plan(account.provider, snapshot.planType)): \(reserve.availableCount.map(String.init) ?? "Unknown") reported available")
                    DialogBodyText("Snapshot fetched \(Format.snapshotDate(snapshot.observedAt, zone: store.state.settings.zone)) · \(account.enabled ? snapshot.health.rawValue.capitalized : "Monitoring paused")")
                    if reserve.hasPartialDetails { DialogBodyText("Provider supplied only partial credit details.") }
                    if let credits = reserve.credits {
                        ForEach(credits) { credit in
                            DialogBodyText("• \(Format.date(credit.expiresAt, zone: store.state.settings.zone)) · \(credit.expiresAt.map { $0 <= store.presentationDate } == true ? "Expired locally — checking provider" : credit.status)")
                                .accessibilityIdentifier("resetCredit-\(credit.id)")
                        }
                    } else { DialogBodyText("Credit details unavailable") }
                }.font(Theme.dialogBodyFont)
            } else if let window = snapshot.windows.first(where: { windowID == nil || $0.id == windowID }) {
                QuotaDetailsView(account: account, window: window, snapshot: snapshot)
            } else { unavailableDetails }
        } else { unavailableDetails }
    }
    private var unavailableDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            DialogBodyText("This account or quota window is no longer available. Refresh the dashboard to check current connections.")
        }
    }
}

/// Shared Windows-style detail dialog: content-sized body and a separate action footer.
struct DetailsDialog<Content: View>: View {
    let title: String
    var width: CGFloat? = nil
    var maximumHeight: CGFloat = 640
    var closeTitle = "Close"
    var tabToFooter = false
    var primaryTitle: String? = nil
    var primaryAction: (() -> Void)? = nil
    let close: () -> Void
    @ViewBuilder let content: () -> Content

    private var hasPrimaryAction: Bool { primaryTitle != nil && primaryAction != nil }
    var body: some View {
        DialogSizing(width: width, maximumHeight: maximumHeight) {
            // WinUI ContentDialogTitleMargin is 12 points below the natural
            // title line box; body paragraphs keep their own eight-point gaps.
            VStack(alignment: .leading, spacing: 12) {
                DialogTextSizing(preferredWidth: ReferenceTypography.dialogTextWidth(title, size: 22, semibold: true)) {
                    Text(title).font(Theme.dialogTitleFont).foregroundStyle(Theme.accent)
                        .referenceNativeTextLineMetrics(size: 22)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ViewThatFits(in: .vertical) {
                    content().fixedSize(horizontal: false, vertical: true)
                    ScrollView { content() }
                }
                .font(Theme.dialogBodyFont)
                .foregroundStyle(Theme.dialogText)
                .textSelection(.enabled)
                .frame(maxHeight: 420, alignment: .leading)
            }.padding(24)
            Rectangle().fill(Color(hex: "#3B3D47")).frame(height: 1)
            DialogFooterColumns {
                if !hasPrimaryAction {
                    Color.clear.frame(height: 44).accessibilityHidden(true)
                }
                if tabToFooter, let primaryTitle, let primaryAction {
                    EditorFooterButton(title: primaryTitle, action: primaryAction)
                    EditorFooterButton(title: closeTitle, isCancel: true, action: close)
                } else {
                    if let primaryTitle, let primaryAction {
                        Button(action: primaryAction) {
                            DialogFooterLabel(title: primaryTitle)
                                .frame(maxWidth: .infinity)
                        }.buttonStyle(ScroogeButtonStyle())
                    }
                    Button(action: close) {
                        DialogFooterLabel(title: closeTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ScroogeButtonStyle())
                    .keyboardShortcut(.cancelAction)
                }
            }.padding(24)
        }
        .padding(1)
        .fixedSize(horizontal: true, vertical: true)
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

/// Resolve the capped popup width before measuring wrapped content height.
/// A frame around an unconstrained ideal size can retain the one-line height
/// after narrowing long messages, clipping the fixed title and footer.
private struct DialogSizing: Layout {
    var width: CGFloat?
    var maximumHeight: CGFloat
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard subviews.count == 3 else { return .zero }
        let outerWidth: CGFloat
        if let width { outerWidth = width }
        else {
            let ideal = max(subviews[0].sizeThatFits(.unspecified).width,
                            subviews[2].sizeThatFits(.unspecified).width) + 2
            outerWidth = min(548, max(320, ideal))
        }
        let innerWidth = max(0, outerWidth - 2)
        let fitted = subviews.map { $0.sizeThatFits(.init(width: innerWidth, height: nil)) }
        return CGSize(width: innerWidth, height: min(max(0, maximumHeight - 2), fitted.reduce(0) { $0 + $1.height }))
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 3 else { return }
        let footerHeight = subviews[2].sizeThatFits(.init(width: bounds.width, height: nil)).height
        let dividerHeight = subviews[1].sizeThatFits(.init(width: bounds.width, height: nil)).height
        let headerHeight = max(0, bounds.height - footerHeight - dividerHeight)
        var y = bounds.minY
        for (view, height) in zip(subviews, [headerHeight, dividerHeight, footerHeight]) {
            view.place(at: CGPoint(x: bounds.minX, y: y), anchor: .topLeading,
                       proposal: .init(width: bounds.width, height: height))
            y += height
        }
    }
}

/// Report the native text's desired width while retaining narrower parent
/// proposals. Leading placement keeps trailing wrap whitespace outside the ink.
private struct DialogTextSizing: Layout {
    let preferredWidth: CGFloat
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let text = subviews.first else { return .zero }
        let width = max(0, min(proposal.width ?? preferredWidth, preferredWidth))
        let fitted = text.sizeThatFits(.init(width: width, height: nil))
        return CGSize(width: width, height: fitted.height)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, anchor: .topLeading,
                             proposal: .init(width: bounds.width, height: nil))
    }
}

/// ContentDialog's two star columns have equal widths. Their ideal size also
/// contributes to the popup's natural width, including a single Close action.
private struct DialogFooterColumns: Layout {
    private let spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        let count = CGFloat(subviews.count)
        let ideal = subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0
        let width = proposal.width ?? (ideal * count + spacing * (count - 1))
        let column = max(0, (width - spacing * (count - 1)) / count)
        let height = subviews.map { $0.sizeThatFits(.init(width: column, height: nil)).height }.max() ?? 0
        return CGSize(width: width, height: height)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }
        let column = max(0, (bounds.width - spacing * CGFloat(subviews.count - 1)) / CGFloat(subviews.count))
        for (index, view) in subviews.enumerated() {
            view.place(at: CGPoint(x: bounds.minX + CGFloat(index) * (column + spacing), y: bounds.minY),
                       proposal: .init(width: column, height: bounds.height))
        }
    }
}

/// Native ContentDialog footer captures have plain white labels. The Windows
/// action decorator does not replace these template-owned button contents.
private struct DialogFooterLabel: View {
    let title: String
    var body: some View {
        Text(title).font(Theme.dialogBodyFont)
            .referenceNativeTextLineMetrics(size: 14)
            .foregroundStyle(Color.white)
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
        DialogFooterLabel(title: title)
            .foregroundStyle(hovered ? Color.white : Theme.primaryText)
            .environment(\.actionForeground, hovered ? .white : Theme.actionAccent)
            .padding(.horizontal, 16)
            .padding(1)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(hovered ? Theme.activeControl : Theme.control, in: RoundedRectangle(cornerRadius: 10))
            .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(Color(hex: "#45464D"), lineWidth: 1) }
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
        DialogTextSizing(preferredWidth: ReferenceTypography.dialogTextWidth(label + ": " + value,
                         prefixLength: (label + ": ").utf16.count)) {
            Text("\(heading)\(Text(verbatim: value).foregroundColor(Theme.dialogText))")
                .font(Theme.dialogBodyFont)
                .referenceNativeTextLineMetrics(size: 14)
                .frame(minHeight: 19, alignment: .leading)
        }
    }
}

/// Match native paragraph metrics and its short, non-time label emphasis rule.
struct DialogBodyText: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        let parsed = Format.dialogLine(text)
        if let label = parsed.label {
            DetailLine(label: label, value: parsed.value)
        } else {
            DialogTextSizing(preferredWidth: ReferenceTypography.dialogTextWidth(parsed.value)) {
                Text(verbatim: parsed.value).font(Theme.dialogBodyFont)
                    .referenceNativeTextLineMetrics(size: 14)
                    .frame(minHeight: 19, alignment: .leading)
            }
        }
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
                    DialogBodyText(line)
                }
            }
        }.font(Theme.dialogBodyFont).foregroundStyle(Theme.dialogText)
    }
}

struct DialogActionLabel: View {
    @Environment(\.actionForeground) private var foreground
    let title: String
    var processing = false
    var body: some View {
        HStack(spacing: 9) {
            if processing {
                ActionProgressRing()
            } else {
                Text(Format.actionGlyph(title))
                    .font(ReferenceTypography.iconFont(size: 20))
                    .foregroundStyle(foreground)
                    .accessibilityHidden(true)
            }
            Text(title).font(Theme.dialogBodyFont).referenceNativeTextLineMetrics(size: 14)
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
        DetailsDialog(title: title, closeTitle: "Cancel", primaryTitle: actionTitle, primaryAction: confirm, close: cancel) {
            DialogMessage(message: message)
        }
    }
}

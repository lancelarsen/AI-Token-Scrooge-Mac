import SwiftUI

struct ConnectionView: View {
    @Environment(\.dismiss) private var dismiss
    let original: ProviderAccount?
    @State private var selectedProvider: Provider?

    var body: some View {
        if let provider = original?.provider ?? selectedProvider {
            ConnectionForm(provider: provider, original: original)
        } else {
            providerChooser
        }
    }

    private var providerChooser: some View {
        DetailsDialog(title: "Connect Account", width: 320, closeTitle: "Cancel", close: { dismiss() }) {
            VStack(spacing: 10) {
                ForEach(Provider.allCases) { choice in
                    Button { selectedProvider = choice } label: {
                        HStack(spacing: 16) {
                            ProviderIcon(provider: choice, size: 28).accessibilityHidden(true)
                            Text(choice == .codex ? "OpenAI Codex" : choice.rawValue)
                                .font(ReferenceTypography.nativeTextFont(size: 16))
                        }.frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                    }.buttonStyle(ScroogeButtonStyle())
                }
            }.textSelection(.disabled)
        }
    }
}

enum ConnectionPhase {
    case idle, authorizing, committing
    var isBusy: Bool { self != .idle }
    var canCancel: Bool { self != .committing }
}

private struct ConnectionForm: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dashboardHostSize) private var hostSize
    let provider: Provider
    let original: ProviderAccount?

    private enum DevinField { case nickname, workspace }
    @FocusState private var devinFocus: DevinField?
    @State private var workspace: String
    @State private var nickname: String
    @State private var token = ""
    @State private var organization: String
    @State private var allowance: String
    @State private var unit: UsageUnit
    @State private var advanced = false
    @State private var phase = ConnectionPhase.idle
    private var connecting: Bool { phase.isBusy }
    @State private var connectionTask: Task<Void, Never>?
    @State private var error: String?

    init(provider: Provider, original: ProviderAccount?) {
        self.provider = provider
        self.original = original
        _nickname = State(initialValue: original?.nickname ?? (provider == .devin ? "Work" : "Personal"))
        _unit = State(initialValue: original?.unit ?? .credits)
        _workspace = State(initialValue: original?.scope ?? "")
        _allowance = State(initialValue: original?.allowance.map { NSDecimalNumber(decimal: $0).stringValue } ?? "")
        let prefix = "organization:"
        let scope = original?.scope ?? ""
        _organization = State(initialValue: scope.hasPrefix(prefix) ? String(scope.dropFirst(prefix.count)) : "")
    }

    private var panelSize: CGSize {
        guard let hostSize else { return CGSize(width: 1000, height: 800) }
        return CGSize(width: min(1000, max(640, hostSize.width - 48)),
                      height: min(800, max(400, hostSize.height - 64)))
    }

    private var organizationReconnect: Bool {
        original?.provider == .copilot && original?.scope.hasPrefix("organization:") == true
    }

    private var connectionDescription: String {
        switch provider {
        case .codex: "Sign in through OpenAI in your browser. Scrooge keeps this account in its own protected Codex profile and only reads usage limits."
        case .devin: "Paste your usual Devin Enterprise workspace URL and sign in. Scrooge reads your personal monthly ACUs and reset time from My Analytics."
        case .claude: "Sign in through Claude in your browser. Scrooge uses a separate Claude Code profile to read your session and weekly limits. Requires Claude Code 2.1.310 or later."
        case .copilot: (advanced || organizationReconnect) ? "Advanced connection: use a fine-grained token with Plan read permission for personal billing. Organization billing requires authorized administration access. Your token stays protected in macOS Keychain." : "Sign in through GitHub in your browser. Scrooge reads your personal Copilot usage and protects this account’s sign-in in macOS Keychain."
        }
    }
    // Match the native Windows form widths (run 42374233894), while allowing
    // the surrounding scroll view to constrain them on smaller windows.
    private var formContentWidth: CGFloat {
        switch provider {
        case .codex: 550
        case .copilot: (advanced || organizationReconnect) ? 534 : 544
        case .claude: 574
        case .devin: 558
        }
    }
    var body: some View {
        ScrollView {
        VStack(alignment: .leading, spacing: 18) {
            Text("Connect \(provider == .codex ? "OpenAI Codex" : provider.rawValue)").font(.reference(size: 26, weight: .semibold))
                .referenceFallbackLineMetrics(size: 26)
            Text(connectionDescription).font(.reference(size: 14)).foregroundStyle(Theme.secondary)
                .referenceClassicLineMetrics(size: 14)
                .fixedSize(horizontal: false, vertical: true)
            TextField("Account nickname (Personal, Work…)", text: $nickname, prompt: Text("Account nickname (Personal, Work…)").foregroundStyle(Color(hex: "#B6B8C8"))).modifier(ConnectionFieldStyle())
                .focused($devinFocus, equals: .nickname).disabled(connecting)
            if provider == .codex {
                CodexConnectView(nickname: nickname, original: original, phase: $phase)
            } else if provider == .copilot {
                Menu {
                    Picker("", selection: $unit) {
                        Text("AI Credits").font(ReferenceTypography.nativeTextFont()).tag(UsageUnit.credits)
                        Text("Legacy Premium Requests").font(ReferenceTypography.nativeTextFont()).tag(UsageUnit.requests)
                    }.labelsHidden().pickerStyle(.inline)
                } label: {
                    HStack {
                        Text(unit == .credits ? "AI Credits" : "Legacy Premium Requests")
                            .font(ReferenceTypography.nativeTextFont())
                        Spacer()
                        ReferenceDropdownChevron()
                    }.padding(.horizontal, 12).frame(height: 32)
                        .background(Theme.control, in: RoundedRectangle(cornerRadius: 10))
                }.menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden)
                    .accessibilityLabel("Billing Unit").accessibilityValue(unit == .credits ? "AI Credits" : "Legacy Premium Requests")
                    .disabled(original != nil || connecting)
                TextField("Fallback allowance (optional; detected automatically when available)", text: $allowance, prompt: Text("Fallback allowance (optional; detected automatically when available)").foregroundStyle(Color(hex: "#B6B8C8"))).modifier(ConnectionFieldStyle()).disabled(connecting)
                if !organizationReconnect {
                Button { token = ""; error = nil; advanced.toggle() } label: {
                    DialogActionLabel(title: advanced ? "Use Browser Sign-In Instead" : "Use an Access Token Instead")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.buttonStyle(ScroogeButtonStyle()).disabled(connecting)
                }
                if !advanced && !organizationReconnect { GitHubConnectView(nickname: nickname, unit: unit, allowance: allowance, original: original, phase: $phase) } else {
                SecureField("Fine-grained personal access token", text: $token, prompt: Text("Fine-grained personal access token").foregroundStyle(Color(hex: "#B6B8C8"))).modifier(ConnectionFieldStyle()).disabled(connecting)
                TextField("Organization billing owner (optional)", text: $organization, prompt: Text("Organization billing owner (optional)").foregroundStyle(Color(hex: "#B6B8C8"))).modifier(ConnectionFieldStyle())
                    .disabled(original != nil || connecting)
                ConnectionStatusLine(text: error ?? "")
                Button {
                    guard !connecting else { return }
                    phase = .authorizing; error = nil
                    connectionTask = Task {
                        defer { phase = .idle }
                        do {
                            let amount = try GitHubAllowanceInput.parse(allowance)
                            try await store.connectGitHub(nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines), token: token.trimmingCharacters(in: .whitespacesAndNewlines), allowance: amount, unit: unit, organization: organization.trimmingCharacters(in: .whitespacesAndNewlines), replacing: original, onCommitting: { phase = .committing })
                            token = ""; dismiss()
                        } catch { self.error = error.localizedDescription }
                    }
                } label: { DialogActionLabel(title: connecting ? "Connecting…" : "Connect Account", processing: connecting).frame(maxWidth: .infinity, alignment: .leading) }
                    .buttonStyle(ScroogeButtonStyle(processing: connecting)).disabled(connecting || token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } else if provider == .devin {
                TextField("Company Devin Workspace URL", text: $workspace,
                          prompt: Text("Company Devin Workspace URL").foregroundStyle(Color(hex: "#B6B8C8")))
                    .focused($devinFocus, equals: .workspace)
                    .accessibilityLabel("Company Devin Workspace URL")
                    .modifier(ConnectionFieldStyle()).disabled(original != nil || connecting)
                ConnectionStatusLine(text: error ?? "")
                Button {
                    guard !connecting else { return }
                    guard workspace.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || DevinUsage.workspace(workspace) != nil else {
                        error = "Enter your company’s Devin workspace URL, such as https://your-company.devinenterprise.com."
                        devinFocus = .workspace
                        return
                    }
                    guard !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        error = "Enter an account nickname."
                        devinFocus = .nickname
                        return
                    }
                    phase = .authorizing
                    error = "Complete sign-in in the Devin window."
                    connectionTask = Task {
                        defer { phase = .idle }
                        do {
                            try await store.connectDevin(nickname: nickname, workspace: workspace, replacing: original, onCommitting: { phase = .committing })
                            dismiss()
                        } catch is CancellationError { self.error = "Sign-in canceled." }
                        catch { self.error = (error as? ProviderFailure)?.message ?? (error is AccountError ? error.localizedDescription : "Devin sign-in could not be saved. Try again.") }
                    }
                } label: { DialogActionLabel(title: connecting ? "Signing In with Devin…" : "Sign In with Devin", processing: connecting).frame(maxWidth: .infinity, alignment: .leading) }
                    .buttonStyle(ScroogeButtonStyle(processing: connecting)).disabled(connecting)
            } else {
                ClaudeConnectView(nickname: nickname, original: original, phase: $phase)
            }
            Button {
                guard phase.canCancel else { return }
                connectionTask?.cancel()
                dismiss()
            } label: { DialogActionLabel(title: "Cancel").frame(maxWidth: .infinity, alignment: .leading) }
                .buttonStyle(ScroogeButtonStyle()).keyboardShortcut(.cancelAction).disabled(!phase.canCancel)
        }.font(.reference(size: 14)).frame(maxWidth: formContentWidth).padding(32).frame(maxWidth: .infinity, alignment: .top)
        }.referencePanelFrame(size: panelSize).preferredColorScheme(.dark).tint(Theme.accent)
        .interactiveDismissDisabled(!phase.canCancel)
        .onDisappear { if phase.canCancel { connectionTask?.cancel() }; token = "" }

    }
}

private struct ConnectionFieldStyle: ViewModifier {
    @FocusState private var focused: Bool
    func body(content: Content) -> some View {
        content.textFieldStyle(.plain).focused($focused)
            .font(ReferenceTypography.nativeTextFont())
            .padding(.horizontal, 12).frame(height: 32)
            .background(Color(hex: "#2A2B30"), in: RoundedRectangle(cornerRadius: 10))
            .overlay(alignment: .bottom) {
                Rectangle().fill(focused ? Theme.accent : Theme.secondary.opacity(0.55))
                    .frame(height: focused ? 2 : 1).padding(.horizontal, 10)
            }
    }
}

/// WinUI retains the empty status label above the connection action.
struct ConnectionStatusLine: View {
    let text: String
    var body: some View {
        Text(text.isEmpty ? " " : text)
            .foregroundStyle(Theme.secondary)
            .frame(minHeight: 19, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityHidden(text.isEmpty)
    }
}

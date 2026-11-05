import SwiftUI

struct ConnectionView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var provider: Provider = .copilot
    @State private var providerChosen = false
    @Environment(\.dashboardHostSize) private var hostSize
    private var panelSize: CGSize {
        guard let hostSize else { return CGSize(width: 1000, height: 800) }
        return CGSize(width: min(1000, max(640, hostSize.width - 48)),
                      height: min(800, max(400, hostSize.height - 64)))
    }
    @State private var nickname = ""
    @State private var token = ""
    @State private var organization = ""
    @State private var allowance = ""
    @State private var unit: UsageUnit = .credits
    @State private var advanced = false
    private var organizationReconnect: Bool {
        guard let id = store.reconnectAccountID,
              let original = store.state.accounts.first(where: { $0.id == id }) else { return false }
        return original.provider == .copilot && original.scope.hasPrefix("organization:")
    }
    @State private var connecting = false
    @State private var connectionTask: Task<Void, Never>?
    @State private var error: String?
    var body: some View {
        Group {
            if providerChosen || store.reconnectAccountID != nil { connectionForm }
            else { providerChooser }
        }
    }

    private var providerChooser: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Connect account").font(.system(size: 21, weight: .semibold)).foregroundStyle(Theme.accent)
                    .frame(minHeight: 32, alignment: .leading)
                ForEach([Provider.codex, .copilot, .claude]) { choice in
                    Button {
                        provider = choice
                        nickname = "Personal"
                        providerChosen = true
                    } label: {
                        DialogActionLabel(title: choice == .codex ? "OpenAI Codex" : choice.rawValue, symbol: "person")
                            .frame(maxWidth: .infinity)
                    }.buttonStyle(ScroogeButtonStyle())
                }
            }.padding(24)
            Rectangle().fill(Color(hex: "#3B3D47")).frame(height: 1)
            HStack {
                Spacer()
                Button { dismiss() } label: { DialogActionLabel(title: "Cancel", symbol: "xmark").frame(minWidth: 98) }
                    .buttonStyle(ScroogeButtonStyle()).keyboardShortcut(.cancelAction)
            }.padding(24)
        }.frame(width: 320).background(Theme.dialogBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16).strokeBorder(Color(hex: "#65577F"), lineWidth: 1)
                    .allowsHitTesting(false)
            }
            .presentationCornerRadius(16)
            .preferredColorScheme(.dark)
    }
    private var connectionDescription: String {
        switch provider {
        case .codex: "Sign in through OpenAI in your browser. Scrooge keeps this account in its own protected Codex profile and only reads usage limits."
        case .claude: "Sign in through Claude in your browser. Scrooge uses a separate Claude Code profile to read your session and weekly limits. Requires Claude Code 2.1.310 or later."
        case .copilot: (advanced || organizationReconnect) ? "Advanced connection: use a fine-grained token with Plan read permission for personal billing. Organization billing requires authorized administration access. Your token stays protected in macOS Keychain." : "Sign in through GitHub in your browser. Scrooge reads your personal Copilot usage and protects this account’s sign-in in macOS Keychain."
        }
    }
    // Match the rendered form widths in reference images21–25 while allowing
    // the surrounding scroll view to constrain them on smaller windows.
    private var formContentWidth: CGFloat {
        switch provider {
        case .codex: 550
        case .copilot: (advanced || organizationReconnect) ? 534 : 544
        case .claude: 576
        }
    }
    private var connectionForm: some View {
        ScrollView {
        VStack(alignment: .leading, spacing: 18) {
            Text("Connect \(provider == .codex ? "OpenAI Codex" : provider.rawValue)").font(.system(size: 26, weight: .semibold))
                .frame(minHeight: 35, alignment: .topLeading)
            Text(connectionDescription).font(.system(size: 14)).foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)
            TextField("Account nickname (Personal, Work…)", text: $nickname).modifier(ConnectionFieldStyle())
            if provider == .codex {
                CodexConnectView(nickname: nickname, original: store.state.accounts.first { $0.id == store.reconnectAccountID })
            } else if provider == .copilot {
                Menu {
                    Button("AI credits") { unit = .credits }
                    Button("Legacy premium requests") { unit = .requests }
                } label: {
                    HStack {
                        Text(unit == .credits ? "AI credits" : "Legacy premium requests")
                        Spacer()
                        Image(systemName: "chevron.down").font(.system(size: 10))
                    }.padding(.horizontal, 12).frame(height: 32)
                        .background(Theme.control, in: RoundedRectangle(cornerRadius: 10))
                }.menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden)
                    .accessibilityLabel("Billing Unit").accessibilityValue(unit == .credits ? "AI credits" : "Legacy premium requests")
                TextField("Fallback allowance (optional; detected automatically when available)", text: $allowance).modifier(ConnectionFieldStyle())
                if !organizationReconnect {
                Button { token = ""; error = nil; advanced.toggle() } label: {
                    DialogActionLabel(title: advanced ? "Use browser sign-in instead" : "Use an access token instead", symbol: advanced ? "arrow.up.right.square" : "key")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.buttonStyle(ScroogeButtonStyle()).disabled(connecting)
                }
                if !advanced && !organizationReconnect { GitHubConnectView(nickname: nickname, unit: $unit, allowance: $allowance) } else {
                SecureField("Fine-grained personal access token", text: $token).modifier(ConnectionFieldStyle())
                TextField("Organization billing owner (optional)", text: $organization).modifier(ConnectionFieldStyle())
                ConnectionStatusLine(text: error ?? "")
                Button {
                    connecting = true; error = nil
                    connectionTask = Task {
                        defer { connecting = false }
                        do {
                            let enteredAllowance = allowance.trimmingCharacters(in: .whitespacesAndNewlines)
                            let amount = enteredAllowance.isEmpty ? nil : Decimal(string: enteredAllowance, locale: Locale(identifier: "en_US_POSIX"))
                            guard enteredAllowance.isEmpty || (amount != nil && amount! > 0) else { throw ProviderFailure(message: "Allowance must be a positive number, or blank.") }
                            try await store.connectGitHub(nickname: nickname, token: token.trimmingCharacters(in: .whitespacesAndNewlines), allowance: amount, unit: unit, organization: organization.trimmingCharacters(in: .whitespacesAndNewlines))
                            token = ""; dismiss()
                        } catch { self.error = error.localizedDescription }
                    }
                } label: { DialogActionLabel(title: connecting ? "Connecting…" : "Connect account", symbol: "person").frame(maxWidth: .infinity, alignment: .leading) }
                    .buttonStyle(ScroogeButtonStyle()).disabled(connecting || token.isEmpty || nickname.isEmpty)
                }
            } else {
                ClaudeConnectView(nickname: nickname, original: store.state.accounts.first { $0.id == store.reconnectAccountID })
            }
            Button { dismiss() } label: { DialogActionLabel(title: "Cancel", symbol: "xmark").frame(maxWidth: .infinity, alignment: .leading) }
                .buttonStyle(ScroogeButtonStyle()).keyboardShortcut(.cancelAction).disabled(connecting)
        }.font(.system(size: 14)).frame(maxWidth: formContentWidth).padding(32).frame(maxWidth: .infinity, alignment: .top)
        }.frame(width: panelSize.width, height: panelSize.height).background(Color(hex: "#141519")).preferredColorScheme(.dark).tint(Theme.accent)
        .onDisappear { connectionTask?.cancel(); token = "" }
        .onAppear {
            if let original = store.state.accounts.first(where: { $0.id == store.reconnectAccountID }) {
                provider = original.provider; nickname = original.nickname; unit = original.unit
                if original.scope.hasPrefix("organization:") { advanced = true; organization = String(original.scope.dropFirst(13)) }
                allowance = original.allowance.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
            }
        }
    }
}

private struct ConnectionFieldStyle: ViewModifier {
    @FocusState private var focused: Bool
    func body(content: Content) -> some View {
        content.textFieldStyle(.plain).focused($focused)
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

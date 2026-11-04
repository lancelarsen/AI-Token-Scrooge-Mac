import SwiftUI

struct ConnectionView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var provider: Provider = .copilot
    @State private var providerChosen = false
    @State private var panelSize = CGSize(width: 1000, height: 800)
    @State private var nickname = ""
    @State private var token = ""
    @State private var organization = ""
    @State private var allowance = ""
    @State private var unit: UsageUnit = .credits
    @State private var advanced = false
    @State private var connecting = false
    @State private var connectionTask: Task<Void, Never>?
    @State private var error: String?
    var body: some View {
        Group {
            if providerChosen || store.reconnectAccountID != nil { connectionForm }
            else { providerChooser }
        }.onAppear {
            if let window = NSApp.keyWindow {
                let host = window.sheetParent ?? window
                let size = host.contentView?.bounds.size ?? host.frame.size
                panelSize = CGSize(width: min(1000, max(640, size.width - 48)), height: min(800, max(400, size.height - 64)))
            }
        }
    }
    private var providerChooser: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Connect account").font(.system(size: 21, weight: .semibold)).foregroundStyle(Theme.accent)
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
            Divider().overlay(Theme.border)
            HStack {
                Spacer()
                Button { dismiss() } label: { DialogActionLabel(title: "Cancel", symbol: "xmark") }
                    .buttonStyle(ScroogeButtonStyle()).keyboardShortcut(.cancelAction)
            }.padding(24)
        }.frame(width: 320).background(Theme.card).preferredColorScheme(.dark)
    }
    private var connectionDescription: String {
        switch provider {
        case .codex: "Sign in through OpenAI in your browser. Scrooge keeps this account in its own protected Codex profile and only reads usage limits."
        case .claude: "Sign in through Claude in your browser. Scrooge uses a separate Claude Code profile to read your session and weekly limits. Requires Claude Code 2.1.310 or later."
        case .copilot: advanced ? "Advanced connection: use a fine-grained token with Plan read permission for personal billing. Organization billing requires authorized administration access. Your token stays protected in macOS Keychain." : "Sign in through GitHub in your browser. Scrooge reads your personal Copilot usage and protects this account’s sign-in in macOS Keychain."
        }
    }
    private var connectionForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Connect \(provider == .codex ? "OpenAI Codex" : provider.rawValue)").font(.system(size: 26, weight: .semibold))
            Text(connectionDescription).foregroundStyle(Theme.secondary).fixedSize(horizontal: false, vertical: true)
            TextField("Nickname", text: $nickname).frame(height: 32)
            if provider == .codex {
                CodexConnectView(nickname: nickname, original: store.state.accounts.first { $0.id == store.reconnectAccountID })
            } else if provider == .copilot {
                Picker("Billing Unit", selection: $unit) { Text("AI Credits").tag(UsageUnit.credits); Text("Premium Requests").tag(UsageUnit.requests) }.labelsHidden().frame(height: 32)
                TextField("Fallback allowance (optional; detected automatically when available)", text: $allowance).frame(height: 32)
                Button { advanced.toggle() } label: {
                    DialogActionLabel(title: advanced ? "Use browser sign-in instead" : "Use an access token instead", symbol: advanced ? "arrow.up.right.square" : "key")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.buttonStyle(ScroogeButtonStyle()).disabled(connecting)
                if !advanced { GitHubConnectView(nickname: nickname, unit: $unit, allowance: $allowance) } else {
                SecureField("GitHub Token", text: $token)
                TextField("Organization (optional)", text: $organization)
                Button {
                    connecting = true; error = nil
                    connectionTask = Task {
                        defer { connecting = false }
                        do {
                            let amount = allowance.isEmpty ? nil : Decimal(string: allowance, locale: Locale(identifier: "en_US_POSIX"))
                            guard allowance.isEmpty || (amount != nil && amount! >= 0) else { throw ProviderFailure(message: "Enter a non-negative monthly allowance, or leave it blank.") }
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
            if let error { Text(error).foregroundStyle(Theme.amber) }
            Button { dismiss() } label: { DialogActionLabel(title: "Cancel", symbol: "xmark").frame(maxWidth: .infinity, alignment: .leading) }
                .buttonStyle(ScroogeButtonStyle()).keyboardShortcut(.cancelAction).disabled(connecting)
            Spacer(minLength: 0)
        }.font(.system(size: 14)).textFieldStyle(.roundedBorder).frame(maxWidth: 550).padding(32).frame(width: panelSize.width, height: panelSize.height, alignment: .top).background(Theme.background).preferredColorScheme(.dark).tint(Theme.accent)
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

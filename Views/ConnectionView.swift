import SwiftUI

struct ConnectionView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var provider: Provider = .copilot
    @State private var nickname = ""
    @State private var token = ""
    @State private var organization = ""
    @State private var allowance = ""
    @State private var unit: UsageUnit = .credits
    @State private var advanced = false
    @State private var connecting = false
    @State private var error: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack { Text("Connect Account").font(.title); Spacer(); Button("Cancel") { dismiss() }.disabled(connecting) }
            Picker("Provider", selection: $provider) { ForEach(Provider.allCases) { Text($0.rawValue).tag($0) } }
            TextField("Nickname", text: $nickname)
            if provider == .codex {
                CodexConnectView(nickname: nickname, original: store.state.accounts.first { $0.id == store.reconnectAccountID })
            } else if provider == .copilot {
                Toggle("Advanced Token Connection", isOn: $advanced).disabled(connecting)
                if !advanced { GitHubConnectView(nickname: nickname) } else {
                Text("Advanced token connection").font(.headline)
                Text("Use a GitHub token with Plan read access. It is saved in your Mac’s Keychain.").foregroundStyle(Theme.secondary)
                SecureField("GitHub Token", text: $token)
                TextField("Organization (optional)", text: $organization)
                Picker("Billing Unit", selection: $unit) { Text("AI Credits").tag(UsageUnit.credits); Text("Premium Requests").tag(UsageUnit.requests) }
                TextField("Monthly Allowance (optional)", text: $allowance)
                Text("Provider allowance takes precedence when available.").font(.caption).foregroundStyle(Theme.secondary)
                Button(connecting ? "Connecting…" : "Connect Account") {
                    connecting = true; error = nil
                    Task {
                        defer { connecting = false }
                        do {
                            let amount = allowance.isEmpty ? nil : Decimal(string: allowance, locale: Locale(identifier: "en_US_POSIX"))
                            guard allowance.isEmpty || (amount != nil && amount! >= 0) else { throw ProviderFailure(message: "Enter a non-negative monthly allowance, or leave it blank.") }
                            try await store.connectGitHub(nickname: nickname, token: token.trimmingCharacters(in: .whitespacesAndNewlines), allowance: amount, unit: unit, organization: organization.trimmingCharacters(in: .whitespacesAndNewlines))
                            token = ""; dismiss()
                        } catch { self.error = error.localizedDescription }
                    }
                }.buttonStyle(ScroogeButtonStyle()).disabled(connecting || token.isEmpty || nickname.isEmpty)
                }
            } else {
                ClaudeConnectView(nickname: nickname, original: store.state.accounts.first { $0.id == store.reconnectAccountID })
            }
            if let error { Text(error).foregroundStyle(Theme.amber) }
        }.padding(28).frame(width: 560).background(Theme.background).preferredColorScheme(.dark)
        .onAppear {
            if let original = store.state.accounts.first(where: { $0.id == store.reconnectAccountID }) {
                provider = original.provider; nickname = original.nickname; unit = original.unit
                if original.scope.hasPrefix("organization:") { advanced = true; organization = String(original.scope.dropFirst(13)) }
                allowance = original.allowance.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
            }
        }
    }
}

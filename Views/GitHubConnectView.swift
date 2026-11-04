import SwiftUI

struct GitHubConnectView: View {
    let nickname: String
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Binding var unit: UsageUnit
    @Binding var allowance: String
    @State private var challenge: GitHubChallenge?
    @State private var task: Task<Void, Never>?
    @State private var busy = false
    @State private var committing = false
    @State private var status = ""
    private let flow = GitHubDeviceFlow()
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !status.isEmpty { Text(status).foregroundStyle(Theme.secondary) }
            if let challenge {
                Text(challenge.userCode).font(.system(size: 30, weight: .semibold, design: .monospaced)).textSelection(.enabled)
                Text("Enter this code on GitHub. Only approve a code you started here.").font(.callout)
                HStack {
                    Button("Copy Code") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(challenge.userCode, forType: .string) }
                    Button("Open GitHub") { NSWorkspace.shared.open(challenge.verificationURL) }
                }.buttonStyle(ScroogeButtonStyle())
            }
            Button { begin() } label: { DialogActionLabel(title: busy ? "Waiting for GitHub…" : "Sign in with GitHub", symbol: "person").frame(maxWidth: .infinity, alignment: .leading) }
                .buttonStyle(ScroogeButtonStyle()).disabled(busy || nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            if busy { ProgressView().controlSize(.small) }
        }.onDisappear { if !committing { task?.cancel() }; challenge = nil }
        .onAppear {
            if let original = store.state.accounts.first(where: { $0.id == store.reconnectAccountID }) {
                unit = original.unit; allowance = original.allowance.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
            }
        }
    }
    private func begin() {
        busy = true
        task = Task {
            defer { busy = false; challenge = nil }
            do {
                let amount = allowance.isEmpty ? nil : Decimal(string: allowance, locale: Locale(identifier: "en_US_POSIX"))
                guard allowance.isEmpty || (amount != nil && amount! >= 0) else { throw ProviderFailure(message: "Enter a non-negative allowance, or leave it blank.") }
                let code = try await flow.begin()
                try Task.checkCancellation()
                challenge = code
                status = "Complete sign-in in your browser. Scrooge will confirm your account when GitHub approves it."
                NSWorkspace.shared.open(code.verificationURL)
                let tokens = try await flow.wait(code)
                try Task.checkCancellation()
                committing = true
                defer { committing = false }
                try await store.connectGitHub(nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines), token: tokens.accessToken, allowance: amount, unit: unit, organization: "", appTokens: tokens)
                dismiss()
            } catch {
                status = (error as? ProviderFailure)?.message ?? (error is AccountError || error is StoreError ? error.localizedDescription : "GitHub sign-in could not be completed. Please try again.")
            }
        }
    }
}

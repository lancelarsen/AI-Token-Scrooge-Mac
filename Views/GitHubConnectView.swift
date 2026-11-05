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
        VStack(alignment: .leading, spacing: 18) {
            ConnectionStatusLine(text: status)
            Button { begin() } label: { DialogActionLabel(title: busy ? "Waiting for GitHub…" : "Sign in with GitHub").frame(maxWidth: .infinity, alignment: .leading) }
                .buttonStyle(ScroogeButtonStyle()).disabled(busy || nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            if busy { ProgressView().controlSize(.small) }
            if let challenge {
                VStack(spacing: 10) {
                    Text("Enter this code on GitHub, then approve AI Reset Radar (the registered sign-in app for AI Token Scrooge).")
                        .font(.reference(size: 14)).multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    Text(challenge.userCode)
                        .font(.reference(size: 28, weight: .semibold)).foregroundStyle(Theme.actionAccent)
                        .frame(maxWidth: .infinity).textSelection(.enabled)
                        .accessibilityLabel("GitHub sign-in code. Enter this code only on github.com.")
                        .accessibilityValue(challenge.userCode)
                    Button {
                        NSPasteboard.general.clearContents()
                        status = NSPasteboard.general.setString(challenge.userCode, forType: .string)
                            ? "Code copied. Paste it into GitHub to continue."
                            : "Could not copy the code. Enter the code shown below directly on GitHub."
                    } label: {
                        DialogActionLabel(title: "Copy code").frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Button {
                        if !NSWorkspace.shared.open(challenge.verificationURL) {
                            status = "Could not open GitHub. Open github.com/login/device in your browser and enter the code shown here."
                        }
                    } label: {
                        DialogActionLabel(title: "Open GitHub").frame(maxWidth: .infinity, alignment: .leading)
                    }
                }.buttonStyle(ScroogeButtonStyle())
            }

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
                let enteredAllowance = allowance.trimmingCharacters(in: .whitespacesAndNewlines)
                let amount = enteredAllowance.isEmpty ? nil : Decimal(string: enteredAllowance, locale: Locale(identifier: "en_US_POSIX"))
                guard enteredAllowance.isEmpty || (amount != nil && amount! > 0) else { throw ProviderFailure(message: "Allowance must be a positive number, or blank.") }
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

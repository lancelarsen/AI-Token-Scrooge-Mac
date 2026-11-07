import SwiftUI

struct ClaudeConnectView: View {
    let nickname: String
    let original: ProviderAccount?
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var operation: Task<Void, Never>?
    @State private var status = ""
    @Binding var phase: ConnectionPhase
    private var busy: Bool { phase.isBusy }
    @State private var closed = false
    private let client = ClaudeClient()
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ConnectionStatusLine(text: status)
            Button {
                guard !busy else { return }
                let credentialID = UUID().uuidString
                phase = .authorizing
                operation = Task {
                    defer { phase = .idle; store.endCredentialAttempt(credentialID) }
                    do {
                        try await store.stageCredential(provider: .claude, id: credentialID)
                        let (account, snapshot) = try await client.connect(credentialID: credentialID, nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines), original: original)
                        try Task.checkCancellation()
                        guard !closed else { return }
                        phase = .committing
                        try await store.acceptConnection(account, snapshot: snapshot, replacing: original)
                        dismiss()
                    } catch {
                        status = (error as? ProviderFailure)?.message ?? (error is AccountError ? error.localizedDescription : "Claude connection could not be completed. Please try again.")
                    }
                }
            } label: { DialogActionLabel(title: busy ? "Waiting for Claude Sign-In…" : "Sign In with Claude", processing: busy).frame(maxWidth: .infinity, alignment: .leading) }
            .buttonStyle(ScroogeButtonStyle(processing: busy)).disabled(busy || nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }.onDisappear {
            closed = true
            if phase.canCancel { operation?.cancel() }
        }
    }
}

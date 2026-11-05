import SwiftUI

struct ClaudeConnectView: View {
    let nickname: String
    let original: ProviderAccount?
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var operation: Task<Void, Never>?
    @State private var status = ""
    @State private var credentialID = UUID().uuidString
    @State private var busy = false
    @State private var committed = false
    @State private var committing = false
    @State private var closed = false
    private let client = ClaudeClient()
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ConnectionStatusLine(text: status)
            Button {
                busy = true
                operation = Task {
                    defer { busy = false; store.endCredentialAttempt(credentialID) }
                    do {
                        try await store.stageCredential(provider: .claude, id: credentialID)
                        let (account, snapshot) = try await client.connect(credentialID: credentialID, nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines), original: original)
                        try Task.checkCancellation()
                        guard !closed else { return }
                        committing = true
                        defer { committing = false }
                        try await store.acceptConnection(account, snapshot: snapshot, replacing: original)
                        committed = true; dismiss()
                    } catch {
                        status = (error as? ProviderFailure)?.message ?? (error is AccountError ? error.localizedDescription : "Claude connection could not be completed. Please try again.")
                    }
                }
            } label: { DialogActionLabel(title: busy ? "Waiting for Claude Sign-In…" : "Sign in with Claude").frame(maxWidth: .infinity, alignment: .leading) }
            .buttonStyle(ScroogeButtonStyle()).disabled(busy || nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            if busy { ProgressView().controlSize(.small) }
        }.onDisappear {
            closed = true
            if !committing { operation?.cancel() }
        }
    }
}

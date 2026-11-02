import SwiftUI

struct ClaudeConnectView: View {
    let nickname: String
    let original: ProviderAccount?
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var operation: Task<Void, Never>?
    @State private var status = "Sign in with your Claude subscription. Scrooge uses an isolated Claude Code profile."
    @State private var credentialID = UUID().uuidString
    @State private var busy = false
    @State private var committed = false
    @State private var committing = false
    @State private var closed = false
    private let client = ClaudeClient()
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(status).foregroundStyle(Theme.secondary)
            Button(busy ? "Waiting for Claude Sign-In…" : "Sign In with Claude") {
                busy = true
                operation = Task {
                    defer { busy = false }
                    do {
                        let (account, snapshot) = try await client.connect(credentialID: credentialID, nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines), original: original)
                        try Task.checkCancellation()
                        guard !closed else { return }
                        committing = true
                        defer { committing = false }
                        try await store.acceptConnection(account, snapshot: snapshot, replacing: original)
                        committed = true; dismiss()
                    } catch {
                        status = (error as? ProviderFailure)?.message ?? (error is AccountError ? error.localizedDescription : "Claude connection could not be completed. Please try again.")
                        if !committed { try? await client.disconnect(credentialID) }
                    }
                }
            }.buttonStyle(ScroogeButtonStyle()).disabled(busy || nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            if busy { ProgressView().controlSize(.small) }
        }.onDisappear {
            closed = true
            if !committing { operation?.cancel() }
        }
    }
}

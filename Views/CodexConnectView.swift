import SwiftUI

struct CodexConnectView: View {
    let nickname: String
    let original: ProviderAccount?
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var connection: CodexConnection?
    @State private var credentialID: String?
    @State private var loginID: String?
    @State private var status = ""
    @State private var busy = false
    @State private var actionRequested = false
    @State private var busyTitle = "Signing In with OpenAI…"
    @State private var committed = false
    @State private var committing = false
    @State private var closed = false
    @State private var listener: Task<Void, Never>?
    private var working: Bool { busy || actionRequested }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ConnectionStatusLine(text: status)
            Button {
                guard !working, !closed else { return }
                busyTitle = connection == nil ? "Signing In with OpenAI…" : "Checking Sign-In…"
                actionRequested = true
                Task {
                    defer { actionRequested = false }
                    if connection == nil { await start() } else { await finish() }
                }
            } label: {
                DialogActionLabel(title: working ? busyTitle : connection == nil ? "Sign In with OpenAI" : "Check Sign-In", processing: working)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(ScroogeButtonStyle(processing: working)).disabled(working || nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .onDisappear { closed = true; listener?.cancel(); if !committing && !busy { Task { await cleanup() } } }
    }
    private func start() async {
        guard !busy, !closed else { return }
        let credentialID = UUID().uuidString
        self.credentialID = credentialID
        busyTitle = "Signing In with OpenAI…"
        busy = true
        defer { busy = false; if closed { Task { await cleanup() } } }
        do {
            try await store.stageCredential(provider: .codex, id: credentialID)
            let opened = try await CodexConnection.start(credentialID: credentialID)
            guard !closed else { await opened.close(); return }
            connection = opened
            let login = try await opened.call("account/login/start", parameters: .object(["type": .string("chatgpt")]))
            loginID = login["loginId"].string
            guard let text = login["authUrl"].string, let url = URL(string: text), url.scheme == "https",
                  let host = url.host?.lowercased(), host == "auth.openai.com" || host.hasSuffix(".openai.com"),
                  url.user == nil, url.password == nil else { throw ProviderFailure(message: "OpenAI returned an unexpected sign-in address.") }
            guard !closed else { await cleanup(); return }
            guard NSWorkspace.shared.open(url) else { throw ProviderFailure(message: "The browser could not open. Please try again.") }
            status = "Complete sign-in in your browser. This window will check the account when you finish."
            listener = Task {
                for await event in opened.notifications {
                    guard !Task.isCancelled, !closed else { return }
                    if event["method"].string == "account/login/completed" {
                        await finish()
                    }
                }
            }
        } catch { status = safeMessage(error); await cleanup() }
    }
    private func finish() async {
        guard !busy, !closed, let connection, let credentialID else { return }
        busyTitle = "Checking Sign-In…"
        busy = true
        defer { busy = false; if closed { Task { await cleanup() } } }
        do {
            let identity = try await connection.call("account/read", parameters: .object(["refreshToken": .bool(false)]))
            guard let email = identity["account"]["email"].string, !email.isEmpty else {
                throw ProviderFailure(message: "Complete sign-in with a ChatGPT account in your browser, then check again.", health: .authenticationRequired)
            }
            let limits = try await connection.call("account/rateLimits/read")
            var account = ProviderAccount(provider: .codex, nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines), subject: email,
                scope: limits["accountId"].string ?? "unresolved", credentialID: credentialID)
            if let original {
                account.id = original.id
                try AccountPolicy.validateReconnect(original: original, replacement: account)
            }
            var snapshot = try ProviderMapping.codex(account: account, response: limits, observed: .now)
            snapshot.planType = identity["account"]["planType"].string
            guard !closed else { return }
            committing = true
            defer { committing = false }
            try await store.acceptConnection(account, snapshot: snapshot, replacing: original)
            committed = true
            await cleanup(); dismiss()
        } catch { status = safeMessage(error); if closed { await cleanup() } }
    }
    private func cleanup() async {
        guard let credentialID else { return }
        self.credentialID = nil
        defer { store.endCredentialAttempt(credentialID) }
        guard let owned = connection else { return }
        connection = nil
        let login = loginID; loginID = nil
        // Give cancellation/logout a short grace period, then close the owned process.
        let timeout = Task { try? await Task.sleep(for: .seconds(3)); await owned.close() }
        if let login { _ = try? await owned.call("account/login/cancel", parameters: .object(["loginId": .string(login)])) }
        if !committed { _ = try? await owned.call("account/logout") }
        await owned.close(); timeout.cancel()
    }
    private func safeMessage(_ error: Error) -> String {
        if let failure = error as? ProviderFailure { return failure.message }
        if error is AccountError || error is StoreError { return error.localizedDescription }
        return "Could not complete the connection. Check provider sign-in and try again."
    }
}

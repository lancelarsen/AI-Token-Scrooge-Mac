import AppKit
import WebKit

/// A fresh browser per operation. Only the per-connection Keychain entry survives closing it.
@MainActor final class DevinClient: NSObject, WKNavigationDelegate, NSWindowDelegate, WKUIDelegate {
    typealias Navigate = (WKWebView, URLRequest) -> Void
    private let load: Navigate

    init(load: @escaping Navigate = { view, request in view.load(request) }) {
        self.load = load
    }

    private let dataStore = WKWebsiteDataStore.nonPersistent()
    private lazy var web: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = dataStore
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        let view = WKWebView(frame: NSRect(x: 0, y: 0, width: 1000, height: 760), configuration: configuration)
        view.navigationDelegate = self
        view.uiDelegate = self
        return view
    }()
    private var window: NSWindow?
    private var closed = false
    private var finished = false
    private var failure: ProviderFailure?
    private static let expired = ProviderFailure(message: "Your Devin sign-in expired. Sign in again.", health: .authenticationRequired)
    private static let unsupported = ProviderFailure(message: "Devin did not show the expected account or monthly usage. Check My Analytics in your workspace.", health: .unsupported)

    static func read(account: ProviderAccount, secrets: SecretStore, interactive: Bool) async throws -> QuotaSnapshot {
        let previous = interactive ? nil : try await secrets.read(account.credentialID)
        if !interactive && previous == nil { throw expired }
        let result = try await DevinClient().observe(account: account, session: previous, interactive: interactive)
        try Task.checkCancellation()
        try await secrets.save(result.session, id: account.credentialID, allowInteraction: interactive)
        return result.snapshot
    }

    func observe(account: ProviderAccount, session: Data?, interactive: Bool) async throws -> (snapshot: QuotaSnapshot, session: Data) {
        defer { web.stopLoading(); window?.close() }
        if interactive {
            let panel = NSWindow(contentRect: web.bounds, styleMask: [.titled, .closable, .resizable],
                                 backing: .buffered, defer: false)
            panel.isReleasedWhenClosed = false
            panel.title = "Sign In with Devin"
            panel.contentView = web
            panel.delegate = self
            panel.center()
            window = panel
            panel.makeKeyAndOrderFront(nil)
        }
        if let session { try await restore(session, host: account.scope) }
        let deadline = ContinuousClock.now.advanced(by: .seconds(interactive ? 600 : 45))
        let origin: URL
        if interactive && account.scope.isEmpty && account.subject.isEmpty && session == nil {
            origin = try await discoverWorkspace(deadline: deadline)
        } else {
            guard let workspace = DevinUsage.workspace(account.scope) else { throw Self.unsupported }
            origin = workspace
        }
        guard let host = origin.host else { throw Self.unsupported }
        let preferences = origin.appendingPathComponent("settings/preferences")
        let identity = #"document.querySelector('#profile-user-id p')?.innerText?.trim().slice(0, 161) || null"#
        func subject(allowLogin: Bool) async throws -> String {
            guard let id = try await self.page(preferences, script: identity, allowLogin: allowLogin, deadline: deadline) as? String,
                  id.wholeMatch(of: /[A-Za-z0-9:|_-]{1,160}/) != nil else { throw Self.unsupported }
            guard account.subject.isEmpty || id == account.subject else { throw AccountError.differentIdentity }
            return id
        }
        let before = try await subject(allowLogin: interactive)
        window?.orderOut(nil)
        guard let fields = try await self.page(origin.appendingPathComponent("settings/my-analytics"), script: Self.usageScript,
                                                  allowLogin: false, deadline: deadline) as? [String] else { throw Self.unsupported }
        guard try await subject(allowLogin: false) == before else { throw AccountError.differentIdentity }
        let now = Date.now
        let usage = try DevinUsage.window(fields, observed: now)
        let updatedSession = try await capture(host: host)
        try Task.checkCancellation()
        let snapshot = QuotaSnapshot(accountID: account.id, subject: before, scope: host, observedAt: now,
                             windows: [usage], planType: "enterprise")
        return (snapshot, updatedSession)
    }

    private func discoverWorkspace(deadline: ContinuousClock.Instant) async throws -> URL {
        load(web, URLRequest(url: URL(string: "https://app.devin.ai/login")!))
        while ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(250))
            if closed { throw CancellationError() }
            if let failure { throw failure }
            // Only consider the browser's top-level destination. SSO pages, links,
            // and redirect parameters are never used as the workspace.
            guard finished, !web.isLoading, let page = web.url,
                  page.scheme == "https", let workspace = DevinUsage.workspace(page.absoluteString),
                  !page.path.hasPrefix("/auth/"), page.path != "/login" else { continue }
            return workspace
        }
        throw ProviderFailure(message: "Devin did not open an Enterprise workspace. Enter your company workspace URL and try again.", health: .authenticationRequired)
    }

    // The WebKit export covers localStorage. HTTP-only cookies must go through the cookie store.
    private struct Session: Codable {
        let host: String
        let storage: Data
        let cookieProperties: Data
    }
    private func capture(host: String) async throws -> Data {
        let types: Set<String> = [WKWebsiteDataTypeLocalStorage]
        // The SSO provider may have created its own storage during sign-in.
        let otherSites = await dataStore.dataRecords(ofTypes: types).filter {
            $0.displayName != host && $0.displayName != "devinenterprise.com"
        }
        if !otherSites.isEmpty { await dataStore.removeData(ofTypes: types, for: otherSites) }
        let storage = try await dataStore.fetchData(of: types)
        let cookies = await dataStore.httpCookieStore.allCookies().filter { cookie in
            let domain = cookie.domain
            return domain == host || (domain.hasPrefix(".") && (host == String(domain.dropFirst()) || host.hasSuffix(domain)))
        }
        let properties = cookies.compactMap { cookie in
            cookie.properties?.reduce(into: [String: Any]()) { dict, entry in
                dict[entry.key.rawValue] = (entry.value as? URL)?.absoluteString ?? entry.value
            }
        }
        let encoded = try PropertyListSerialization.data(fromPropertyList: properties, format: .binary, options: 0)
        return try PropertyListEncoder().encode(Session(host: host, storage: storage, cookieProperties: encoded))
    }
    private func restore(_ bytes: Data, host: String) async throws {
        let session = try PropertyListDecoder().decode(Session.self, from: bytes)
        guard session.host == host,
              let rows = try PropertyListSerialization.propertyList(from: session.cookieProperties, format: nil) as? [[String: Any]]
        else { throw Self.expired }
        try await dataStore.restoreData(session.storage)
        for row in rows {
            guard let cookie = HTTPCookie(properties: Dictionary(uniqueKeysWithValues: row.map { (HTTPCookiePropertyKey($0.key), $0.value) }))
            else { throw Self.expired }
            try Task.checkCancellation()
            await dataStore.httpCookieStore.setCookie(cookie)
        }
    }

    private func page(_ target: URL, script: String, allowLogin: Bool, deadline: ContinuousClock.Instant) async throws -> Any {
        let origin = "https://" + (target.host ?? "")
        // Both checks execute in the same document as the read, in an isolated JS world.
        let expression = "location.origin === '\(origin)' && location.pathname === '\(target.path)' ? (\(script)) : null"
        func navigate() {
            finished = false
            failure = nil
            load(web, URLRequest(url: target, cachePolicy: .reloadIgnoringLocalCacheData))
        }
        navigate()
        var arrived: ContinuousClock.Instant?
        var retried = false
        while ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(350))
            if closed { throw CancellationError() }
            if let failure { throw failure }
            guard finished, !web.isLoading, let url = web.url else { continue }
            guard url.scheme == "https", url.host == target.host, (url.port ?? 443) == 443, url.path == target.path else {
                arrived = nil
                if allowLogin {
                    if url.host == target.host && url.path.hasPrefix("/org/") && !retried { retried = true; navigate() }
                    continue
                }
                if url.host != target.host || url.path.hasPrefix("/auth/") { throw Self.expired }
                throw ProviderFailure(message: "Your account could not open Devin My Analytics.", health: .permissionRequired)
            }
            let first = arrived ?? .now
            arrived = first
            let elapsed = first.duration(to: .now)
            let value = try? await web.evaluateJavaScript(expression, in: nil, contentWorld: .defaultClient)
            if let value, !(value is NSNull) {
                if let fields = value as? [String], fields.count == 4, fields[1].isEmpty || fields[2].isEmpty {
                    if elapsed >= .seconds(12) { return fields }
                } else { return value }
            }
            if elapsed > .seconds(14) { throw Self.unsupported }
        }
        throw ProviderFailure(message: "The Devin check timed out. Please try again.", health: .stale)
    }

    func windowWillClose(_ notification: Notification) { closed = true }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { finished = false }
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let url = webView.url, let host = url.host { window?.title = "Sign In with Devin — " + host }
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        failure = ProviderFailure(message: "The Devin browser closed unexpectedly. Try again.")
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { finished = true }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { loadFailed(error) }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { loadFailed(error) }
    private func loadFailed(_ error: Error) {
        if (error as NSError).code != NSURLErrorCancelled && failure == nil {
            failure = ProviderFailure(message: "The Devin page could not load. Check your connection and try again.")
        }
    }
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
        action.request.url?.scheme == "https" && action.targetFrame != nil && !action.shouldPerformDownload ? .allow : .cancel
    }
    func webView(_ webView: WKWebView, decidePolicyFor response: WKNavigationResponse) async -> WKNavigationResponsePolicy {
        if let http = response.response as? HTTPURLResponse,
           http.value(forHTTPHeaderField: "Content-Disposition")?.lowercased().hasPrefix("attachment") == true { return .cancel }
        if response.isForMainFrame, let http = response.response as? HTTPURLResponse {
            failure = Self.responseFailure(http.statusCode)
        }
        return failure == nil && response.canShowMIMEType ? .allow : .cancel
    }
    static func responseFailure(_ status: Int) -> ProviderFailure? {
        switch status {
        case 401: expired
        case 403: ProviderFailure(message: "Your account lacks access to the Devin page.", health: .permissionRequired)
        case 429: ProviderFailure(message: "Devin asked Scrooge to slow down.", health: .stale, retryAt: .now.addingTimeInterval(900))
        case 400...599: ProviderFailure(message: "The Devin page is unavailable.")
        default: nil
        }
    }

    func webView(_ webView: WKWebView, decideMediaCapturePermissionsFor origin: WKSecurityOrigin, initiatedBy frame: WKFrameInfo, type: WKMediaCaptureType) async -> WKPermissionDecision { .deny }

    static let usageScript = #"""
        (() => {
            const text = document.querySelector('#main-content')?.innerText ?? '';
            const amount = '([0-9][0-9,.]*)';
            const numbers = text.match(new RegExp(amount + '\\s*\\/\\s*' + amount + '\\s*\\(\\s*[0-9.]+\\s*%\\s*\\)\\s*ACUs consumed since', 'i'));
            const monthly = text.match(/Monthly ACU limit usage\s+([0-9][0-9,.]*)\s*\/\s*([0-9][0-9,.]*)/i);
            const meter = numbers ?? monthly;
            const used = text.match(/Monthly ACUs consumed\s+([0-9][0-9,.]*)/i);
            if (!meter && !used) return null;
            const reset = text.match(/Resets\s+(\d{1,2}\/\d{1,2})\s+at\s+(\d{1,2}:\d{2}\s*[AP]M)/i);
            return [(meter?.[1] ?? used[1]).slice(0, 41), (meter?.[2] ?? '').slice(0, 41), reset ? reset[1] + ' ' + reset[2] : '',
                Intl.DateTimeFormat().resolvedOptions().timeZone ?? ''];
        })()
        """#
}

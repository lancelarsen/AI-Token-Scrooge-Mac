import WebKit
import XCTest
@testable import AITokenScrooge

final class DevinTests: XCTestCase {
    private let observed = ISO8601DateFormatter().date(from: "2026-12-27T12:00:00Z")!

    func testTrustedTenantAndPrivatePathRemoval() {
        let origin = "https://work.devinenterprise.com"
        XCTAssertEqual(DevinUsage.workspace(origin + "/org/example?next=private")?.absoluteString, origin)
        XCTAssertEqual(DevinUsage.workspace("WORK.devinenterprise.com")?.absoluteString, origin)
        for invalid in ["http://work.devinenterprise.com", "https://user@work.devinenterprise.com",
                        "https://work.devinenterprise.com:444", "work.devinenterprise.com.example",
                        "devinenterprise.com", "x.y.devinenterprise.com"] {
            XCTAssertNil(DevinUsage.workspace(invalid))
        }
    }

    func testACUsOverageMonthlyHistoryAndUnknownAllowance() throws {
        let window = try DevinUsage.window(["1,001.5", "900", "1/16 2:00 AM", "America/Chicago"], observed: observed)
        XCTAssertEqual(window.used, 1001.5)
        XCTAssertEqual(window.resetsAt, ISO8601DateFormatter().date(from: "2027-01-16T08:00:00Z"))
        XCTAssertEqual(Format.usageText(window, provider: .devin).used, "111% Used")
        XCTAssertEqual(Format.usageText(window, provider: .devin).left, "0% Left")
        XCTAssertEqual(UsageHistory.selectWindow(provider: .devin, windows: [window]).window, window)
        let unknown = try DevinUsage.window(["0", "", "5/16 2:00 AM", "UTC"], observed: observed)
        XCTAssertEqual(unknown.used, 0)
        XCTAssertNil(unknown.limit)
        XCTAssertNil(unknown.resetsAt)
        XCTAssertEqual(Format.usageText(unknown, provider: .devin).left, "Left Unavailable")
        for value in ["Loading", "1,2,34", "-1"] {
            XCTAssertThrowsError(try DevinUsage.window([value, "100", "", ""], observed: observed))
        }
    }

    func testAmbiguousAndSkippedResetTimesStayUnknown() throws {
        for (date, reset) in [("2026-10-30T10:00:00Z", "11/1 1:30 AM"), ("2026-03-01T10:00:00Z", "3/8 2:30 AM")] {
            let start = ISO8601DateFormatter().date(from: date)!
            XCTAssertNil(try DevinUsage.window(["1", "2", reset, "America/Chicago"], observed: start).resetsAt)
        }
    }

    @MainActor func testAccessErrorsAndRetryDeadline() {
        XCTAssertEqual(DevinClient.responseFailure(401)?.health, .authenticationRequired)
        XCTAssertEqual(DevinClient.responseFailure(403)?.health, .permissionRequired)
        let throttled = DevinClient.responseFailure(429)
        XCTAssertEqual(throttled?.health, .stale)
        XCTAssertGreaterThan(throttled?.retryAt?.timeIntervalSinceNow ?? 0, 890)
        XCTAssertNil(DevinClient.responseFailure(200))
    }

    @MainActor func testCancellingPendingSignInClosesOwnedBrowser() async throws {
        let navigated = expectation(description: "Isolated sign-in browser opened")
        var signInWindow: NSWindow?
        let client = DevinClient { view, _ in
            signInWindow = view.window
            navigated.fulfill()
            // Hold the browser on an unfinished sign-in without contacting a provider.
        }
        let pending = ProviderAccount(provider: .devin, nickname: "Work", subject: "", scope: "")
        let operation = Task { try await client.observe(account: pending, session: nil, interactive: true) }
        await fulfillment(of: [navigated], timeout: 3)
        XCTAssertEqual(signInWindow?.isVisible, true)
        operation.cancel()
        do {
            _ = try await operation.value
            XCTFail("Canceled sign-in must not return an authenticated session")
        } catch is CancellationError {
            // Cancellation must also tear down the owned browser window.
        } catch { XCTFail("Unexpected sign-in failure: \(error)") }
        XCTAssertEqual(signInWindow?.isVisible, false)
    }

    @MainActor func testEmailFirstSignInBindsVerifiedTenant() async throws {
        var requests: [URL] = []
        let tenant = "fixture.devinenterprise.com"
        let client = DevinClient { view, request in
            let url = request.url!
            requests.append(url)
            let destination: URL
            let html: String
            if url.host == "app.devin.ai" {
                // Simulate the browser landing on the tenant after company login.
                destination = URL(string: "https://" + tenant + "/org/fixture")!
                html = "<p>Workspace</p>"
            } else {
                destination = url
                html = url.path == "/settings/preferences" ? "<div id='profile-user-id'><p>fixture-user</p></div>" :
                    "<main id='main-content'>Monthly ACU limit usage 25 / 100<br>Resets 1/16 at 2:00 AM</main>"
            }
            let response = HTTPURLResponse(url: destination, statusCode: 200, httpVersion: "HTTP/1.1",
                                           headerFields: ["Content-Type": "text/html"])!
            view.loadSimulatedRequest(URLRequest(url: destination), response: response, responseData: Data(html.utf8))
        }
        let pending = ProviderAccount(provider: .devin, nickname: "Work", subject: "", scope: "")
        let result = try await client.observe(account: pending, session: nil, interactive: true)
        XCTAssertEqual(requests.first?.absoluteString, "https://app.devin.ai/login")
        XCTAssertEqual(requests.dropFirst().map(\.host), [tenant, tenant, tenant])
        XCTAssertEqual(result.snapshot.scope, tenant)
        XCTAssertEqual(result.snapshot.subject, "fixture-user")
        XCTAssertEqual(result.snapshot.windows.first?.usedPercent, 25)
    }

    // Real WebKit navigations with simulated HTTPS responses. The second browser must
    // recover both cookie and localStorage from the same payload used by Keychain.
    @MainActor func testIsolatedBrowserSessionRefreshAndIdentityChange() async throws {
        let account = ProviderAccount(provider: .devin, nickname: "Work", subject: "user-1", scope: "sample.devinenterprise.com")
        func browser(seed: Bool, swap: Bool = false) -> DevinClient {
            var visits = 0
            return DevinClient { view, request in
                let url = request.url!
                var headers = ["Content-Type": "text/html"]
                let page: String
                if url.path == "/settings/preferences" {
                    visits += 1
                    let bootstrap = seed && visits == 1 ? "localStorage.setItem('sample','fixture'); document.cookie='sample=yes; Secure; Path=/';" : ""
                    let user = swap && visits > 1 ? "changed-user" : "user-1"
                    page = """
                    <div id="profile-user-id"><p></p></div><script>
                    \(bootstrap)
                    document.querySelector('p').textContent =
                    (localStorage.getItem('sample') === 'fixture' && document.cookie.includes('sample=yes')) ? '\(user)' : 'missing-session';
                    </script>
                    """
                } else {
                    page = "<main id='main-content'>Monthly ACU limit usage 250 / 1,000<br>Resets 1/16 at 2:00 AM</main>"
                }
                headers["Cache-Control"] = "no-store"
                let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)!
                view.loadSimulatedRequest(request, response: response, responseData: Data(page.utf8))
            }
        }
        let initial = try await browser(seed: true).observe(account: account, session: nil, interactive: false)
        XCTAssertEqual(initial.snapshot.windows.first?.usedPercent, 25)
        let refresh = try await browser(seed: false).observe(account: account, session: initial.session, interactive: false)
        XCTAssertEqual(refresh.snapshot.subject, "user-1")
        do {
            _ = try await browser(seed: false, swap: true).observe(account: account, session: refresh.session, interactive: false)
            XCTFail("A switched account must not contribute a usage reading")
        } catch AccountError.differentIdentity { }
    }
}

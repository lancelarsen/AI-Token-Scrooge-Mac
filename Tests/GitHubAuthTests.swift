import XCTest
@testable import AITokenScrooge

final class GitHubAuthTests: XCTestCase {
    func testRetryHeadersRespectDateAndShortProviderDeadline() {
        let now = ISO8601DateFormatter().date(from: "2026-11-02T20:00:00Z")!
        XCTAssertEqual(GitHubClient.retryAfter("60", now: now), now.addingTimeInterval(60))
        XCTAssertEqual(GitHubClient.retryAfter("Mon, 02 Nov 2026 20:10:00 GMT", now: now), now.addingTimeInterval(600))
        for value in ["nan", "inf", "-5", "", "invalid"] { XCTAssertNil(GitHubClient.retryAfter(value, now: now)) }
        XCTAssertEqual(GitHubClient.retryDeadline(now.addingTimeInterval(60), now: now), now.addingTimeInterval(60))
        XCTAssertEqual(GitHubClient.retryDeadline(now.addingTimeInterval(-1), now: now), now.addingTimeInterval(300))
        XCTAssertEqual(GitHubClient.retryDeadline(nil, now: now), now.addingTimeInterval(300))
    }
    func testStrictCredentialValidation() {
        XCTAssertTrue(GitHubDeviceFlow.validClientID("Iv23.example-1"))
        XCTAssertFalse(GitHubDeviceFlow.validClientID("https://example.test"))
        XCTAssertFalse(GitHubDeviceFlow.validSecret("token\nheader"))
        XCTAssertFalse(GitHubDeviceFlow.validSecret(String(repeating: "a", count: 4097)))
    }
    func testTokenResponseRequiresRefreshAndBoundedLifetime() throws {
        let now = Date(timeIntervalSince1970: 1800000000)
        let value = try JSONDecoder().decode(JSONValue.self, from: Data(#"{"access_token":"access-fixture","refresh_token":"refresh-fixture","token_type":"bearer","expires_in":3600,"refresh_token_expires_in":86400}"#.utf8))
        let tokens = try GitHubDeviceFlow.tokens(value, clientID: "fixture", now: now)
        XCTAssertEqual(tokens.expiresAt, now.addingTimeInterval(3600))
        XCTAssertEqual(tokens.refreshExpiresAt, now.addingTimeInterval(86400))
        var missing = value.object!; missing.removeValue(forKey: "refresh_token")
        XCTAssertThrowsError(try GitHubDeviceFlow.tokens(.object(missing), clientID: "fixture", now: now))
        var excessive = value.object!; excessive["expires_in"] = .number(86401)
        XCTAssertThrowsError(try GitHubDeviceFlow.tokens(.object(excessive), clientID: "fixture", now: now))
    }
}

private actor RenewalFixture {
    var data: Data?
    var saves = 0
    var refreshes = 0
    var failSave: Int?
    var failRefresh = false
    func configure(save: Int? = nil, refresh: Bool = false) { failSave = save; failRefresh = refresh }
    func read() -> Data? { data }
    func save(_ value: Data) throws {
        saves += 1
        if saves == failSave { throw SecretStoreError.unavailable }
        data = value
    }
    func remove() { data = nil }
    func refresh(_ old: GitHubAppTokens) throws -> GitHubAppTokens {
        refreshes += 1
        if failRefresh { throw URLError(.networkConnectionLost) }
        var next = old; next.accessToken = "renewed-fixture"; next.refreshToken = "rotated-fixture"
        next.expiresAt = .now.addingTimeInterval(3600)
        return next
    }
    func count() -> Int { refreshes }
    var dependencies: GitHubCredentialManager.Dependencies {
        .init(read: { _ in await self.read() }, save: { value, _ in try await self.save(value) },
              remove: { _ in await self.remove() }, refresh: { try await self.refresh($0) }, identify: { _ in "subject" })
    }
}

extension GitHubAuthTests {
    private func expiringTokens() -> GitHubAppTokens {
        .init(clientID: "fixture", accessToken: "old-fixture", refreshToken: "refresh-fixture",
              expiresAt: .now, refreshExpiresAt: .now.addingTimeInterval(86400))
    }
    func testRenewedTokenSurvivesWriteFailureWithoutSecondRotation() async throws {
        let fixture = RenewalFixture()
        let manager = GitHubCredentialManager(dependencies: await fixture.dependencies)
        let account = ProviderAccount(provider: .copilot, nickname: "Test", subject: "subject", scope: "scope")
        try await manager.saveApp(id: account.credentialID, subject: account.subject, tokens: expiringTokens())
        await fixture.configure(save: 3) // Initial save, renewal intent, then replacement.
        do { _ = try await manager.accessToken(for: account); XCTFail("Expected write failure") } catch {}
        let token = try await manager.accessToken(for: account)
        XCTAssertEqual(token, "renewed-fixture")
        let rotations = await fixture.count()
        XCTAssertEqual(rotations, 1)
        let reopened = GitHubCredentialManager(dependencies: await fixture.dependencies)
        let restored = try await reopened.accessToken(for: account)
        XCTAssertEqual(restored, token)
    }
    func testAmbiguousNetworkFailureLeavesDurableReconnectMarker() async throws {
        let fixture = RenewalFixture()
        let manager = GitHubCredentialManager(dependencies: await fixture.dependencies)
        let account = ProviderAccount(provider: .copilot, nickname: "Test", subject: "subject", scope: "scope")
        try await manager.saveApp(id: account.credentialID, subject: account.subject, tokens: expiringTokens())
        await fixture.configure(refresh: true)
        do { _ = try await manager.accessToken(for: account); XCTFail("Expected network failure") } catch {}
        let reopened = GitHubCredentialManager(dependencies: await fixture.dependencies)
        do { _ = try await reopened.accessToken(for: account); XCTFail("Expected reconnect") } catch {}
        let rotations = await fixture.count()
        XCTAssertEqual(rotations, 1)
    }
}

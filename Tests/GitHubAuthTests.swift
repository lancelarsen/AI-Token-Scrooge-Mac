import XCTest
@testable import AITokenScrooge

final class GitHubAuthTests: XCTestCase {
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

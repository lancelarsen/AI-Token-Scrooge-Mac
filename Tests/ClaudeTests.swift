import XCTest
@testable import AITokenScrooge

final class ClaudeTests: XCTestCase {
    func testTimedOutCommandThatIgnoresTerminationIsReaped() async throws {
        let process = Process()
        let command = BoundedProcess(process: process)
        do {
            _ = try await command.run(executable: URL(fileURLWithPath: "/bin/sh"),
                arguments: ["-c", "trap '' TERM; exec /bin/sleep 60"],
                directory: FileManager.default.temporaryDirectory, environment: [:], timeout: .milliseconds(200))
            XCTFail("Expected timeout")
        } catch { XCTAssertTrue(error is ProviderFailure) }
        for _ in 0..<30 {
            if !process.isRunning { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        XCTAssertFalse(process.isRunning)
    }
    private func date(_ text: String) -> Date { ISO8601DateFormatter().date(from: text)! }
    func testSupportedVersionGate() {
        XCTAssertFalse(ClaudeClient.supportsUsage("2.1.309 (Claude Code)"))
        XCTAssertTrue(ClaudeClient.supportsUsage("2.1.310 (Claude Code)"))
        XCTAssertTrue(ClaudeClient.supportsUsage("3.0.0 (Claude Code)"))
        XCTAssertFalse(ClaudeClient.supportsUsage("unknown"))
    }
    func testSeparateWindowsAndResetTimes() {
        let now = date("2026-11-02T18:00:00Z")
        let windows = ClaudeUsageParser.parse("""
        Current session
        24% used
        Resets 3pm (America/Chicago)
        Current week (all models)
        62.5% used
        Resets Nov 5, 1pm (America/Chicago)
        Extra usage
        90% used
        """, now: now)
        XCTAssertEqual(windows.count, 2)
        XCTAssertEqual(windows[0].used, 24)
        XCTAssertEqual(windows[0].resetsAt, date("2026-11-02T21:00:00Z"))
        XCTAssertEqual(windows[1].used, Decimal(string: "62.5"))
        XCTAssertEqual(windows[1].resetsAt, date("2026-11-05T19:00:00Z"))
    }
    func testUnknownResetRetainsKnownUsage() {
        let windows = ClaudeUsageParser.parse("Current session\n18% used\nResets tomorrow (Unknown/Zone)", now: date("2026-11-02T18:00:00Z"))
        XCTAssertEqual(windows.first?.used, 18)
        XCTAssertNil(windows.first?.resetsAt)
        XCTAssertTrue(ClaudeUsageParser.parse("Current session\n-5% used", now: .now).isEmpty)
        XCTAssertTrue(ClaudeUsageParser.parse("Current session\n101% used", now: .now).isEmpty)
    }
    func testAmbiguousAndNonexistentCivilTimesAreUnknown() {
        XCTAssertNil(ClaudeUsageParser.parseReset("1:30am", zoneID: "America/Chicago", now: date("2026-11-01T05:00:00Z"), duration: 300))
        XCTAssertNil(ClaudeUsageParser.parseReset("2:30am", zoneID: "America/Chicago", now: date("2026-03-08T06:00:00Z"), duration: 300))
    }
    func testOutOfWindowResetIsUnknown() {
        XCTAssertNil(ClaudeUsageParser.parseReset("11pm", zoneID: "America/Chicago", now: date("2026-11-02T18:00:00Z"), duration: 300))
    }
}

import Darwin
import XCTest
@testable import AITokenScrooge

final class ProviderTransportTests: XCTestCase {
    func testClosedCommandInputThrowsAWriteError() throws {
        let pipe = try Pipe.commandInput()
        // Check the per-descriptor protection before writing, so a regression
        // produces an assertion instead of terminating the whole test host.
        guard fcntl(pipe.fileHandleForWriting.fileDescriptor, F_GETNOSIGPIPE) == 1 else {
            return XCTFail("Command writes must suppress SIGPIPE on their descriptor.")
        }
        try pipe.fileHandleForReading.close()
        XCTAssertThrowsError(try pipe.fileHandleForWriting.writeCommand(Data([10])))
    }

    func testStalledCommandInputDoesNotBlockTheConnection() throws {
        let pipe = try Pipe.commandInput()
        let input = pipe.fileHandleForWriting
        guard fcntl(input.fileDescriptor, F_GETFL) & O_NONBLOCK != 0 else {
            return XCTFail("A full command pipe must not block the connection actor.")
        }
        XCTAssertThrowsError(try input.writeCommand(Data(repeating: 0, count: 2_000_000)))
    }

    func testCommandReturnsCompleteOutputAndRejectsExcess() async throws {
        func output(count: Int) async throws -> Data {
            try await BoundedProcess().run(executable: URL(fileURLWithPath: "/usr/bin/head"),
                arguments: ["-c", String(count), "/dev/zero"],
                directory: FileManager.default.temporaryDirectory, environment: [:])
        }
        let accepted = try await output(count: 2_000_000)
        XCTAssertEqual(accepted, Data(repeating: 0, count: 2_000_000))
        do {
            _ = try await output(count: 2_000_001)
            XCTFail("Expected the command output limit")
        } catch let error as ProviderFailure {
            XCTAssertTrue(error.message.contains("size limit"))
        }
    }

    func testGitHubEntitlementRequiresAnEntireNonnegativeQuantity() {
        func allowance(_ text: String) -> Decimal? {
            let response: JSONValue = .object([
                "copilot_plan": .string("individual"),
                "token_based_billing": .bool(false),
                "quota_snapshots": .object(["premium_interactions": .object([
                    "unlimited": .bool(false), "entitlement": .string(text)
                ])])
            ])
            return ProviderMapping.githubAllowance(response, unit: .requests)
        }
        XCTAssertEqual(allowance("300"), 300)
        XCTAssertEqual(allowance("0"), 0)
        XCTAssertNil(allowance("-1"))
        XCTAssertNil(allowance("100 units"))
        XCTAssertNil(allowance("1,000"))
    }
}

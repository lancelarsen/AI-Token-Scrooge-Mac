import XCTest

final class DashboardUITests: XCTestCase {
    @MainActor func testDemoHistoryToggleAndExit() throws {
        let app = XCUIApplication()
        app.launchEnvironment["SCROOGE_TEST_MODE"] = "1"
        app.launchArguments = ["--demo"]
        app.launch()
        let exit = app.buttons["addAccountButton"]
        XCTAssertTrue(exit.waitForExistence(timeout: 10))
        XCTAssertEqual(exit.label, "Exit Demo")
        let history = app.switches["historyToggle"]
        XCTAssertTrue(history.exists)
        history.click()
        XCTAssertTrue(app.buttons["Show OpenAI Personal on Timeline"].exists, "Selectors must stay visible with history off")
        history.click()
        exit.click()
        XCTAssertTrue(app.buttons["exploreDemoButton"].waitForExistence(timeout: 5))
        app.terminate()
    }
}

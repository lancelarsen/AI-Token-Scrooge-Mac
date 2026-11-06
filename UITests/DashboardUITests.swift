import SQLite3
import XCTest

final class DashboardUITests: XCTestCase {
    @MainActor func testDemoHistoryToggleAndExit() throws {
        let app = XCUIApplication()
        app.launchEnvironment["SCROOGE_TEST_MODE"] = "1"
        app.launchArguments = ["--demo"]
        app.launch()
        defer { app.terminate() }
        let exit = app.buttons["addAccountButton"]
        XCTAssertTrue(exit.waitForExistence(timeout: 10))
        XCTAssertEqual(exit.label, "Exit Demo")
        let history = app.switches["historyToggle"]
        XCTAssertTrue(history.exists)
        history.click()
        XCTAssertTrue(app.buttons["Hide OpenAI / Personal · Plus · Timeline"].exists, "Selectors must stay visible with history off")
        history.click()
        exit.click()
        XCTAssertTrue(app.buttons["exploreDemoButton"].waitForExistence(timeout: 5))
    }

    @MainActor func testCancelReconnectThenAddAccountOffersProviderChoices() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        seedPausedAccount(at: directory.appendingPathComponent("scrooge.db"))

        let app = XCUIApplication()
        app.launchEnvironment["SCROOGE_TEST_MODE"] = "1"
        app.launchArguments = ["--data-dir", directory.path]
        app.launch()
        defer { app.terminate() }

        let manage = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Settings for GitHub Copilot")).firstMatch
        XCTAssertTrue(manage.waitForExistence(timeout: 10))
        manage.click()
        let reconnect = app.buttons["Sign In Again"]
        XCTAssertTrue(reconnect.waitForExistence(timeout: 5))
        reconnect.click()
        XCTAssertTrue(app.staticTexts["Connect GitHub Copilot"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].click()

        app.buttons["addAccountButton"].click()
        XCTAssertTrue(app.staticTexts["Connect Account"].waitForExistence(timeout: 5))
        for provider in ["OpenAI Codex", "GitHub Copilot", "Claude", "Devin"] {
            XCTAssertTrue(app.buttons[provider].exists)
        }
    }

    @MainActor func testClosingAlertHistoryReturnsToSettings() throws {
        let app = XCUIApplication()
        app.launchEnvironment["SCROOGE_TEST_MODE"] = "1"
        app.launch()
        defer { app.terminate() }

        let settings = app.buttons["settingsButton"]
        XCTAssertTrue(settings.waitForExistence(timeout: 10))
        settings.click()
        let history = app.buttons["Alert History"]
        XCTAssertTrue(history.waitForExistence(timeout: 5))
        history.click()
        let emptyHistory = app.staticTexts["No alerts yet. Low capacity and expiring resets will appear here."]
        XCTAssertTrue(emptyHistory.waitForExistence(timeout: 5))

        app.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(emptyHistory.waitForNonExistence(timeout: 5))
        app.buttons["Close"].click()
        XCTAssertTrue(history.waitForNonExistence(timeout: 5))
    }

    private func seedPausedAccount(at url: URL) {
        var database: OpaquePointer?
        let result = sqlite3_open(url.path, &database)
        defer { sqlite3_close(database) }
        XCTAssertEqual(result, SQLITE_OK)
        // A saved account without credentials lets the test enter reconnect without contacting a provider.
        let sql = """
            CREATE TABLE state (id INTEGER PRIMARY KEY, payload BLOB NOT NULL);
            INSERT INTO state VALUES (1, '{"accounts":[{"id":"sample","provider":"GitHub Copilot",
                "nickname":"Work","subject":"sample","scope":"personal","enabled":false,"unit":"credits",
                "credentialID":"8825F897-08B6-441C-BBCE-F58CA0C9BC76","pollingMinutes":2,
                "generation":"EC88AFF0-5D3A-49C1-A7D1-19887D761FB6"}]}');
            """
        XCTAssertEqual(sqlite3_exec(database, sql, nil, nil, nil), SQLITE_OK)
    }
}

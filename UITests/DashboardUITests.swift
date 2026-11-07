import SQLite3
import Vision
import XCTest

final class DashboardUITests: XCTestCase {
    @MainActor func testUnavailableStatusIndicatorAndPrivacy() throws {
        try verifyStatusIndicator(scenario: "permission", summary: "Some Current Usage Data Is Unavailable")
    }

    @MainActor func testCriticalStatusIndicatorAndPrivacy() throws {
        try verifyStatusIndicator(scenario: "healthy", summary: "Critical Alert · Quota Refresh")
    }

    @MainActor private func verifyStatusIndicator(scenario: String, summary: String) throws {
        let app = XCUIApplication()
        app.launchEnvironment["SCROOGE_TEST_MODE"] = "1"
        app.launchArguments = ["--demo", "--reference-wide", "--scenario", scenario]
        app.launch()
        defer { app.terminate() }
        if !app.windows["dashboard"].waitForExistence(timeout: 2) {
            let windowMenu = app.menuBars.menuBarItems["Window"]
            windowMenu.click()
            windowMenu.menuItems["AI Token Scrooge"].click()
        }
        XCTAssertTrue(app.buttons["addAccountButton"].waitForExistence(timeout: 10))
        app.activate()
        let running = try XCTUnwrap(NSRunningApplication.runningApplications(withBundleIdentifier: "com.lancelarsen.AITokenScrooge")
            .max { ($0.launchDate ?? .distantPast) < ($1.launchDate ?? .distantPast) })
        running.activate(options: [.activateIgnoringOtherApps])
        let item = app.statusItems.firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 5), app.debugDescription)
        // AppKit exposes a status item's title, rather than its XCTest label.
        let summaryStatus = app.statusItems.matching(NSPredicate(format: "title CONTAINS %@", summary)).firstMatch
        XCTAssertTrue(summaryStatus.waitForExistence(timeout: 3), item.debugDescription)
        let view = app.menuBars.menuBarItems["View"]
        view.click()
        view.menuItems["Privacy Mode"].click()
        let hidden = app.statusItems.matching(NSPredicate(format: "title CONTAINS %@", "Account Details Hidden")).firstMatch
        if scenario == "healthy" {
            XCTAssertTrue(hidden.waitForExistence(timeout: 3), item.debugDescription)
            XCTAssertFalse(app.statusItems.matching(NSPredicate(format: "title CONTAINS %@", "Personal")).firstMatch.exists)
        } else {
            XCTAssertTrue(summaryStatus.exists, item.debugDescription)
        }
        view.click()
        view.menuItems["Privacy Mode"].click()
        XCTAssertTrue(hidden.waitForNonExistence(timeout: 3), item.debugDescription)
        XCTAssertTrue(summaryStatus.exists)
    }

    @MainActor func testDemoHistoryToggleAndExit() throws {
        let app = XCUIApplication()
        app.launchEnvironment["SCROOGE_TEST_MODE"] = "1"
        app.launchArguments = ["--demo", "--reference-wide"]
        app.launch()
        defer { app.terminate() }
        if !app.windows["dashboard"].waitForExistence(timeout: 2) {
            let windowMenu = app.menuBars.menuBarItems["Window"]
            windowMenu.click()
            windowMenu.menuItems["AI Token Scrooge"].click()
        }
        app.activate()
        let exit = app.buttons["addAccountButton"]
        XCTAssertTrue(exit.waitForExistence(timeout: 10))
        XCTAssertEqual(exit.label, "Exit Demo")
        let history = app.switches["historyToggle"]
        XCTAssertTrue(history.exists)
        history.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        XCTAssertTrue(app.buttons["Hide OpenAI / Personal · Plus · Timeline"].exists, "Selectors must stay visible with history off")
        history.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        let selector = app.buttons["timelineAccount-demo-0"]
        let refresh = app.buttons["timeline-refresh-demo-0/codex/secondary"]
        XCTAssertTrue(refresh.exists)
        selector.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.5)).click()
        XCTAssertTrue(app.buttons["Show OpenAI / Personal · Plus · Timeline"].exists, "The selector margin must toggle account history")
        XCTAssertTrue(refresh.waitForNonExistence(timeout: 3), "Hidden-account changes invalidate prepared future events")
        selector.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.5)).click()
        XCTAssertTrue(app.buttons["Hide OpenAI / Personal · Plus · Timeline"].exists)
        XCTAssertTrue(refresh.waitForExistence(timeout: 3), "Showing the account restores its reset events")
        exit.click()
        XCTAssertTrue(app.buttons["exploreDemoButton"].waitForExistence(timeout: 5))
    }

    @MainActor func testCompactEmptyDashboardControlsRemainReachable() throws {
        let app = XCUIApplication()
        app.launchEnvironment["SCROOGE_TEST_MODE"] = "1"
        app.launchArguments = ["--demo", "--compact", "--reference-date", "2026-11-04T16:16:00Z"]
        app.launch()
        defer { app.terminate() }
        let dashboard = app.windows["dashboard"]
        if !dashboard.waitForExistence(timeout: 2) {
            app.menuBars.menuBarItems["Window"].click()
            app.menuBars.menuBarItems["Window"].menuItems["AI Token Scrooge"].click()
        }
        XCTAssertTrue(app.buttons["addAccountButton"].waitForExistence(timeout: 10))
        app.activate()
        let running = try XCTUnwrap(NSRunningApplication.runningApplications(withBundleIdentifier: "com.lancelarsen.AITokenScrooge")
            .max { ($0.launchDate ?? .distantPast) < ($1.launchDate ?? .distantPast) })
        running.activate(options: [.activateIgnoringOtherApps])
        let activated = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            NSWorkspace.shared.frontmostApplication?.processIdentifier == running.processIdentifier
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [activated], timeout: 3), .completed)
        dashboard.coordinate(withNormalizedOffset: CGVector(dx: 0.06, dy: 0.12)).click()
        if !app.buttons["addAccountButton"].isHittable {
            dashboard.scrollBars.firstMatch.scroll(byDeltaX: 0, deltaY: -250)
        }
        XCTAssertEqual(app.buttons["addAccountButton"].label, "Exit Demo")
        app.buttons["addAccountButton"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        XCTAssertTrue(app.buttons["exploreDemoButton"].waitForExistence(timeout: 5))
        // The empty fixture is isolated from connected accounts. Return to its top after Exit Demo.
        dashboard.scrollBars.firstMatch.scroll(byDeltaX: 0, deltaY: 1600)
        XCTAssertTrue(app.switches["historyToggle"].isHittable)
        XCTAssertTrue(app.buttons["Earned Reset Alert Settings"].isHittable)
        XCTAssertTrue(app.buttons["addAccountButton"].isHittable)
        let capture = XCTAttachment(screenshot: dashboard.screenshot())
        capture.name = "Compact empty horizon with corrected source spacing"
        capture.lifetime = .keepAlways
        add(capture)
    }

    @MainActor func testAccountDragEdgeScrollAndOutsideCancellation() throws {
        let app = XCUIApplication()
        app.launchEnvironment["SCROOGE_TEST_MODE"] = "1"
        app.launchArguments = ["--demo", "--compact", "--reference-date", "2026-11-04T16:16:00Z"]
        app.launch()
        defer { app.terminate() }
        let dashboard = app.windows["dashboard"]
        if !dashboard.waitForExistence(timeout: 2) {
            app.menuBars.menuBarItems["Window"].click()
            app.menuBars.menuBarItems["Window"].menuItems["AI Token Scrooge"].click()
        }
        app.activate()
        let labels = ["OpenAI / Personal", "GitHub Copilot / Work", "OpenAI / Work", "Claude / Personal"]
        func grip(_ account: String) -> XCUIElement {
            dashboard.descendants(matching: .any).matching(NSPredicate(format: "label == %@",
                "Drag \(account) to Reorder Accounts")).firstMatch
        }
        func order() -> [String] { labels.sorted { grip($0).frame.minY < grip($1).frame.minY } }
        let source = grip(labels[0])
        XCTAssertTrue(source.waitForExistence(timeout: 5))
        // Scroll on the vertical scrollbar, outside the horizon's horizontal-wheel routing.
        let scrollbar = dashboard.scrollBars.firstMatch
        for _ in 0..<4 where source.frame.midY > dashboard.frame.maxY - 180 {
            scrollbar.scroll(byDeltaX: 0, deltaY: -250)
        }
        XCTAssertTrue(source.isHittable)
        XCTAssertLessThan(source.frame.midY, dashboard.frame.maxY - 180)
        XCTAssertEqual(order(), labels)
        let startingTop = grip(labels[1]).frame.minY
        let bottom = dashboard.coordinate(withNormalizedOffset: CGVector(dx: 0.09, dy: 0.985))
        source.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .click(forDuration: 0.1, thenDragTo: bottom, withVelocity: .slow, thenHoldForDuration: 1.5)
        let expected = Array(labels.dropFirst()) + [labels[0]]
        let moved = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in order() == expected }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [moved], timeout: 5), .completed)
        XCTAssertLessThan(grip(labels[1]).frame.minY, startingTop - 50,
            "Holding the dragged card at the bottom edge must scroll the actual dashboard")
        let capture = XCTAttachment(screenshot: dashboard.screenshot())
        capture.name = "Compact account order after bottom-edge drag"
        capture.lifetime = .keepAlways
        add(capture)
        // A release over the fixed header cancels and restores the original scroll position.
        let last = grip(labels[0])
        XCTAssertTrue(last.isHittable)
        let beforeCancel = last.frame
        last.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .click(forDuration: 0.1, thenDragTo: dashboard.coordinate(withNormalizedOffset: CGVector(dx: 0.09, dy: 0.12)))
        let restored = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            order() == expected && abs(last.frame.minY - beforeCancel.minY) < 1
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [restored], timeout: 5), .completed)
    }

    @MainActor func testAccountIdentityBlankAreaOpensDetails() throws {
        let app = XCUIApplication()
        app.launchEnvironment["SCROOGE_TEST_MODE"] = "1"
        app.launchArguments = ["--demo", "--reference-wide"]
        app.launch()
        defer { app.terminate() }
        if !app.windows["dashboard"].waitForExistence(timeout: 2) {
            let windowMenu = app.menuBars.menuBarItems["Window"]
            windowMenu.click()
            windowMenu.menuItems["AI Token Scrooge"].click()
        }
        app.activate()
        let identity = app.buttons["OpenAI, Personal · Plus. Open details."].firstMatch
        XCTAssertTrue(identity.waitForExistence(timeout: 10))
        XCTAssertEqual(identity.frame.width, 220, accuracy: 1)
        // Click beyond the intrinsic logo/name content, beside the plan badge.
        identity.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.8)).click()
        let details = app.staticTexts["38% Used · 62% Left"].firstMatch
        XCTAssertTrue(details.waitForExistence(timeout: 5))
        app.buttons["Close"].click()
        XCTAssertTrue(details.waitForNonExistence(timeout: 5))
    }

    @MainActor func testCountUsageDetailsShowOverageAndMissingLimit() throws {
        let app = XCUIApplication()
        app.launchEnvironment["SCROOGE_TEST_MODE"] = "1"
        app.launchArguments = ["--demo", "--reference-wide", "--scenario", "count-usage",
                               "--reference-date", "2026-11-04T16:11:00Z"]
        app.launch()
        defer { app.terminate() }
        if !app.windows["dashboard"].waitForExistence(timeout: 2) {
            let windowMenu = app.menuBars.menuBarItems["Window"]
            windowMenu.click()
            windowMenu.menuItems["AI Token Scrooge"].click()
        }
        app.activate()
        let allowance = app.buttons["Request Allowance. Open Details"].firstMatch
        XCTAssertTrue(allowance.waitForExistence(timeout: 10))
        allowance.click()
        let overage = app.staticTexts["1,250 Used · 250 Over"].firstMatch
        XCTAssertTrue(overage.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Available Resets"].exists)
        app.buttons["Close"].click()
        app.buttons["OpenAI, Personal · Plus. Open details."].firstMatch.click()
        XCTAssertTrue(overage.waitForExistence(timeout: 5), "Account identity opens the first quota even when earned resets exist")
        let sheet = app.sheets.firstMatch
        XCTAssertTrue(sheet.frame.contains(overage.frame), "Count details must fit within their popup")
        XCTAssertGreaterThanOrEqual(sheet.frame.width, 320)
        XCTAssertLessThan(sheet.frame.width, 548, "Short details should use their natural width below the cap")
        XCTAssertEqual(app.buttons["Close"].frame.width, (sheet.frame.width - 58) / 2, accuracy: 1,
                       "Windows reserves half the footer for a single close action")
        app.buttons["Close"].click()
        app.buttons["Unknown Request Limit. Open Details"].firstMatch.click()
        let unavailable = app.staticTexts["50 Used · Limit Unavailable"].firstMatch
        XCTAssertTrue(unavailable.waitForExistence(timeout: 5))
        XCTAssertTrue(app.sheets.firstMatch.frame.contains(unavailable.frame))
        app.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(unavailable.waitForNonExistence(timeout: 5))
    }

    @MainActor func testLongUsageDetailsWrapAtWindowsWidthLimit() throws {
        let app = XCUIApplication()
        app.launchEnvironment["SCROOGE_TEST_MODE"] = "1"
        app.launchArguments = ["--demo", "--reference-wide", "--scenario", "long-details"]
        app.launch()
        defer { app.terminate() }
        if !app.windows["dashboard"].waitForExistence(timeout: 2) {
            let windowMenu = app.menuBars.menuBarItems["Window"]
            windowMenu.click()
            windowMenu.menuItems["AI Token Scrooge"].click()
        }
        app.activate()
        let quota = app.buttons["Codex · 5-Hour. Open Details"].firstMatch
        XCTAssertTrue(quota.waitForExistence(timeout: 10))
        quota.click()
        let note = app.staticTexts["quotaSourceNote"].firstMatch
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        let sheet = app.sheets.firstMatch
        XCTAssertEqual(sheet.frame.width, 548, accuracy: 1)
        XCTAssertGreaterThan(note.frame.height, 38, "Long status text must wrap rather than shrink")
        XCTAssertTrue(sheet.frame.contains(note.frame), "The entire wrapped note must remain inside the popup")
        XCTAssertTrue(app.buttons["Close"].isHittable)
        app.buttons["Close"].click()
        XCTAssertTrue(note.waitForNonExistence(timeout: 5))
    }

    @MainActor func testLongResetDetailsScrollKeepsTitleAndCloseVisible() throws {
        let app = XCUIApplication()
        app.launchEnvironment["SCROOGE_TEST_MODE"] = "1"
        app.launchArguments = ["--demo", "--reference-wide", "--scenario", "many-resets",
                               "--reference-date", "2026-11-04T16:11:00Z"]
        app.launch()
        defer { app.terminate() }
        if !app.windows["dashboard"].waitForExistence(timeout: 2) {
            let windowMenu = app.menuBars.menuBarItems["Window"]
            windowMenu.click()
            windowMenu.menuItems["AI Token Scrooge"].click()
        }
        app.activate()
        let reset = app.buttons["Reset for Codex · Weekly. Open Details"].firstMatch
        XCTAssertTrue(reset.waitForExistence(timeout: 10))
        reset.click()
        let title = app.staticTexts["Available Resets"].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        let titleFrame = title.frame
        let sheet = app.sheets.firstMatch
        let body = sheet.scrollViews.firstMatch
        XCTAssertTrue(body.exists)
        XCTAssertLessThanOrEqual(body.frame.height, 421)
        let close = app.buttons["Close"]
        XCTAssertTrue(close.isHittable)
        let closeFrame = close.frame
        body.scroll(byDeltaX: 0, deltaY: -1600)
        let lastCredit = app.staticTexts["resetCredit-demo-reset-30"].firstMatch
        XCTAssertTrue(lastCredit.exists)
        XCTAssertTrue(body.frame.contains(lastCredit.frame), "The last reset must be reachable by scrolling the body")
        XCTAssertEqual(title.frame, titleFrame, "The dialog title must stay outside the scrolling body")
        XCTAssertEqual(close.frame, closeFrame, "The footer must stay fixed")
        XCTAssertTrue(close.isHittable)
        let capture = XCTAttachment(screenshot: sheet.screenshot())
        capture.name = "Long reset details after scrolling"
        capture.lifetime = .keepAlways
        add(capture)
        close.click()
        XCTAssertTrue(title.waitForNonExistence(timeout: 3))
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

    @MainActor func testRowAlarmWaitsForSaveAndRestoresAfterFailure() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let path = directory.appendingPathComponent("scrooge.db")
        seedPausedAccount(at: path, withQuota: true)
        let app = XCUIApplication()
        app.launchEnvironment["SCROOGE_TEST_MODE"] = "1"
        app.launchArguments = ["--data-dir", directory.path]
        app.launch()
        defer { app.terminate() }
        if !app.windows["dashboard"].waitForExistence(timeout: 2) {
            let menu = app.menuBars.menuBarItems["Window"]
            menu.click(); menu.menuItems["AI Token Scrooge"].click()
        }
        let on = app.buttons["Enable Alerts for AI Credits · Monthly"]
        let off = app.buttons["Disable Alerts for AI Credits · Monthly"]
        XCTAssertTrue(off.waitForExistence(timeout: 10))
        var database: OpaquePointer?
        XCTAssertEqual(sqlite3_open(path.path, &database), SQLITE_OK)
        defer { sqlite3_exec(database, "ROLLBACK", nil, nil, nil); sqlite3_close(database) }
        // Hold the real SQLite write, rather than adding a UI-only delay.
        XCTAssertEqual(sqlite3_exec(database, "BEGIN IMMEDIATE", nil, nil, nil), SQLITE_OK)
        off.click()
        XCTAssertFalse(on.isEnabled)
        XCTAssertFalse(off.isEnabled)
        XCTAssertTrue(on.isSelected, "Retain the saved selection until persistence succeeds")
        XCTAssertEqual(sqlite3_exec(database, "COMMIT", nil, nil, nil), SQLITE_OK)
        let saved = NSPredicate { _, _ in off.isEnabled && off.isSelected && on.isEnabled }
        expectation(for: saved, evaluatedWith: nil)
        waitForExpectations(timeout: 5)
        XCTAssertEqual(sqlite3_exec(database, "CREATE TRIGGER reject_alarm BEFORE UPDATE ON state BEGIN SELECT RAISE(ABORT, 'injected save failure'); END;", nil, nil, nil), SQLITE_OK)
        on.click()
        XCTAssertTrue(app.staticTexts["Scrooge Needs Attention"].waitForExistence(timeout: 5))
        app.buttons["Close"].click()
        XCTAssertTrue(off.isSelected, "Failed writes must preserve the previous alarm selection")
        XCTAssertTrue(on.isEnabled)
        XCTAssertTrue(off.isEnabled)
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
        let testNotification = app.buttons["Send Test Notification"]
        XCTAssertTrue(testNotification.exists, "The notification test must expose its action name")
        XCTAssertTrue(testNotification.isEnabled)
        history.click()
        let emptyHistory = app.staticTexts["No alerts yet. Low capacity and expiring resets will appear here."]
        XCTAssertTrue(emptyHistory.waitForExistence(timeout: 5))

        app.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(emptyHistory.waitForNonExistence(timeout: 5))
        app.buttons["Close"].click()
        XCTAssertTrue(history.waitForNonExistence(timeout: 5))
    }

    @MainActor func testAccountSettingsCloseSavesFocusedNickname() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        seedPausedAccount(at: directory.appendingPathComponent("scrooge.db"))
        let app = XCUIApplication()
        app.launchEnvironment["SCROOGE_TEST_MODE"] = "1"
        app.launchArguments = ["--data-dir", directory.path]
        app.launch()
        defer { app.terminate() }
        if !app.windows["dashboard"].waitForExistence(timeout: 2) {
            let windowMenu = app.menuBars.menuBarItems["Window"]
            windowMenu.click()
            windowMenu.menuItems["AI Token Scrooge"].click()
        }
        let settings = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Settings for GitHub Copilot / Work")).firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 10))
        settings.click()
        let name = app.textFields["Account Name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.click()
        name.typeKey("a", modifierFlags: .command)
        name.typeText("Business")
        var database: OpaquePointer?
        XCTAssertEqual(sqlite3_open(directory.appendingPathComponent("scrooge.db").path, &database), SQLITE_OK)
        defer { sqlite3_close(database) }
        XCTAssertEqual(sqlite3_exec(database, "CREATE TRIGGER reject_name BEFORE UPDATE ON state BEGIN SELECT RAISE(ABORT, 'injected save failure'); END;", nil, nil, nil), SQLITE_OK)
        // Do not submit or leave the field before pressing Close.
        app.buttons["Close"].click()
        XCTAssertTrue(app.staticTexts["settingsSaveStatus"].waitForExistence(timeout: 5))
        XCTAssertTrue(name.exists, "A failed save must leave account settings open")
        XCTAssertEqual(name.value as? String, "Business", "Retain the unsaved draft for retry")
        XCTAssertEqual(sqlite3_exec(database, "DROP TRIGGER reject_name", nil, nil, nil), SQLITE_OK)
        app.buttons["Close"].click()
        XCTAssertTrue(name.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Settings for GitHub Copilot / Business")).firstMatch.exists)
        var statement: OpaquePointer?
        XCTAssertEqual(sqlite3_prepare_v2(database, "SELECT payload FROM state WHERE id=1", -1, &statement, nil), SQLITE_OK)
        defer { sqlite3_finalize(statement) }
        XCTAssertEqual(sqlite3_step(statement), SQLITE_ROW)
        let bytes = try XCTUnwrap(sqlite3_column_blob(statement, 0))
        let data = Data(bytes: bytes, count: Int(sqlite3_column_bytes(statement, 0)))
        let state = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let accounts = try XCTUnwrap(state["accounts"] as? [[String: Any]])
        XCTAssertEqual(accounts.first?["nickname"] as? String, "Business")
    }

    @MainActor func testSettingsCloseKeepsInvalidReminderDraftOpen() throws {
        let app = XCUIApplication()
        app.launchEnvironment["SCROOGE_TEST_MODE"] = "1"
        app.launchArguments = ["--demo", "--reference-wide"]
        app.launch()
        defer { app.terminate() }
        if !app.windows["dashboard"].waitForExistence(timeout: 2) {
            let windowMenu = app.menuBars.menuBarItems["Window"]
            windowMenu.click()
            windowMenu.menuItems["AI Token Scrooge"].click()
        }
        app.buttons["settingsButton"].click()
        let amount = app.textFields["Time Before Event"].firstMatch
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        amount.click()
        amount.typeKey("a", modifierFlags: .command)
        amount.typeText("0")
        app.buttons["Close"].click()
        XCTAssertTrue(app.staticTexts["settingsSaveStatus"].waitForExistence(timeout: 3))
        XCTAssertTrue(amount.exists)
        XCTAssertEqual(amount.value as? String, "0")
        amount.click()
        amount.typeKey("a", modifierFlags: .command)
        amount.typeText("2")
        XCTAssertTrue(app.staticTexts["settingsSaveStatus"].waitForNonExistence(timeout: 3))
        app.buttons["Close"].click()
        XCTAssertTrue(amount.waitForNonExistence(timeout: 5))
    }

    @MainActor func testColorPickerKeyboardModeAndExactSwatch() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let app = XCUIApplication()
        app.launchEnvironment["SCROOGE_TEST_MODE"] = "1"
        app.launchArguments = ["--demo", "--reference-wide", "--data-dir", directory.path]
        app.launch()
        defer { app.terminate() }

        let settings = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Settings for OpenAI / Personal")).firstMatch
        if !app.windows["dashboard"].waitForExistence(timeout: 2) {
            // The last session may have closed its dashboard to the menu bar.
            let windowMenu = app.menuBars.menuBarItems["Window"]
            windowMenu.click()
            windowMenu.menuItems["AI Token Scrooge"].click()
        }
        guard settings.waitForExistence(timeout: 10) else {
            XCTFail("Demo account settings unavailable")
            return
        }
        settings.click()
        XCTAssertTrue(app.textFields["Account Name"].waitForExistence(timeout: 5))
        let capture = XCTAttachment(screenshot: app.sheets.firstMatch.screenshot())
        capture.name = "Wide account settings with Windows border inset"
        capture.lifetime = .keepAlways
        add(capture)
        app.buttons["Add Custom Line Color"].click()
        let hex = app.textFields.matching(NSPredicate(format: "placeholderValue == %@", "Hex Color")).firstMatch
        XCTAssertTrue(hex.waitForExistence(timeout: 5))
        hex.click()
        hex.typeKey("a", modifierFlags: .command)
        hex.typeText("#123456")

        app.typeKey(.tab, modifierFlags: .shift)
        app.typeKey(.space, modifierFlags: [])
        app.typeKey(.downArrow, modifierFlags: [])
        app.typeKey(.return, modifierFlags: [])
        let hsv = app.textFields.matching(NSPredicate(format: "placeholderValue == %@", "Hue")).firstMatch
        XCTAssertTrue(hsv.waitForExistence(timeout: 3))
        // Tab across Hex, Hue, Saturation and Value. Merely leaving rounded
        // display fields must never quantize the original RGB bytes.
        for _ in 0..<5 { app.typeKey(.tab, modifierFlags: []) }
        XCTAssertEqual(hex.value as? String, "#123456")
        app.typeKey(.return, modifierFlags: [])
        let saved = app.buttons["Line Color #123456"]
        XCTAssertTrue(saved.waitForExistence(timeout: 5))

        app.buttons["Add Custom Line Color"].click()
        XCTAssertEqual(hex.value as? String, "#123456")
        hex.click()
        hex.typeKey("a", modifierFlags: .command)
        hex.typeText("#ABCDEF")
        // R, G, B, Add Color, Cancel. Space dismisses the draft.
        for _ in 0..<5 { app.typeKey(.tab, modifierFlags: []) }
        app.typeKey(.space, modifierFlags: [])
        XCTAssertTrue(hex.waitForNonExistence(timeout: 3))
        app.buttons["Add Custom Line Color"].click()
        XCTAssertEqual(hex.value as? String, "#123456")
        app.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(hex.waitForNonExistence(timeout: 3))
    }

    @MainActor func testQuietHoursHandlesKeyboardAndDisabledInput() throws {
        let app = XCUIApplication()
        app.launchEnvironment["SCROOGE_TEST_MODE"] = "1"
        app.launchArguments = ["--demo", "--reference-wide"]
        app.launch()
        defer { app.terminate() }
        let dashboard = app.windows["dashboard"]
        if !dashboard.waitForExistence(timeout: 2) {
            app.menuBars.menuBarItems["Window"].click()
            app.menuBars.menuBarItems["Window"].menuItems["AI Token Scrooge"].click()
        }
        let running = try XCTUnwrap(NSRunningApplication.runningApplications(withBundleIdentifier: "com.lancelarsen.AITokenScrooge")
            .max { ($0.launchDate ?? .distantPast) < ($1.launchDate ?? .distantPast) })
        running.activate(options: [.activateIgnoringOtherApps])
        dashboard.coordinate(withNormalizedOffset: CGVector(dx: 0.06, dy: 0.08)).click()
        app.buttons["settingsButton"].click()
        let panel = app.sheets.firstMatch
        let start = panel.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Quiet Hours Start")).firstMatch
        let end = panel.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Quiet Hours End")).firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        for _ in 0..<6 {
            if start.frame.minY > panel.frame.minY + 90 && start.frame.maxY < panel.frame.maxY - 120 { break }
            panel.scrollViews.firstMatch.scroll(byDeltaX: 0, deltaY: -200)
        }
        XCTAssertTrue(panel.frame.contains(start.frame))
        let toggle = panel.switches["Quiet Hours"]
        if !start.isEnabled { toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click() }
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in start.isEnabled }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 3), .completed)
        XCTAssertTrue(panel.staticTexts["12 AM – 8 AM · 8 hours"].exists)
        let initialStart = start.frame.midX, initialEnd = end.frame.midX
        let span = (initialEnd - initialStart) * 24 / 8
        let startKnob = start.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).withOffset(CGVector(dx: 0, dy: 28))
        startKnob.click(forDuration: 0.1, thenDragTo: startKnob.withOffset(CGVector(dx: -span * 4 / 24, dy: 0)))
        XCTAssertTrue(panel.staticTexts["8 PM – 8 AM · 12 hours · Overnight"].waitForExistence(timeout: 3))
        XCTAssertEqual(end.frame.midX, initialEnd, accuracy: 1, "Dragging Start must leave End unchanged")
        let endKnob = end.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).withOffset(CGVector(dx: 0, dy: 28))
        endKnob.click(forDuration: 0.1, thenDragTo: endKnob.withOffset(CGVector(dx: span * 2 / 24, dy: 0)))
        XCTAssertTrue(panel.staticTexts["8 PM – 10 AM · 14 hours · Overnight"].waitForExistence(timeout: 3))
        XCTAssertEqual(start.frame.midX, initialStart - span * 4 / 24, accuracy: 1)
        start.click()
        app.typeKey(.rightArrow, modifierFlags: [])
        XCTAssertTrue(panel.staticTexts["9 PM – 10 AM · 13 hours · Overnight"].waitForExistence(timeout: 3))
        app.typeKey(.leftArrow, modifierFlags: [])
        XCTAssertTrue(panel.staticTexts["8 PM – 10 AM · 14 hours · Overnight"].waitForExistence(timeout: 3))
        let capture = XCTAttachment(screenshot: panel.screenshot())
        capture.name = "Quiet hours independent handles and keyboard focus"
        capture.lifetime = .keepAlways
        add(capture)
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        let disabled = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in !start.isEnabled }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [disabled], timeout: 3), .completed)
        // Send the physical drag through panel coordinates; do not invoke a disabled AX control.
        let point = start.frame
        let disabledKnob = panel.coordinate(withNormalizedOffset: .zero).withOffset(
            CGVector(dx: point.midX - panel.frame.minX, dy: point.midY + 28 - panel.frame.minY))
        disabledKnob.click(forDuration: 0.1, thenDragTo: disabledKnob.withOffset(CGVector(dx: 60, dy: 0)))
        app.typeKey(.rightArrow, modifierFlags: [])
        XCTAssertTrue(panel.staticTexts["8 PM – 10 AM · 14 hours · Overnight"].exists,
            "Disabled quiet hours reject pointer and key changes")
        app.buttons["Close"].click()
    }

    @MainActor func testThresholdReadoutTracksDragAndDismisses() throws {
        try verifyThresholdReadout(severity: "Warning", initialRemaining: 30)
    }

    @MainActor func testInfoThresholdReadoutTracksDragAndDismisses() throws {
        try verifyThresholdReadout(severity: "Info", initialRemaining: 50)
    }

    @MainActor func testCriticalThresholdReadoutTracksDragAndDismisses() throws {
        try verifyThresholdReadout(severity: "Critical", initialRemaining: 10)
    }

    @MainActor func testCompactThresholdReadoutTracksDragAndDismisses() throws {
        try verifyThresholdReadout(severity: "Warning", initialRemaining: 30, compact: true)
    }

    @MainActor private func verifyThresholdReadout(severity: String, initialRemaining: CGFloat, compact: Bool = false) throws {
        let app = XCUIApplication()
        app.launchEnvironment["SCROOGE_TEST_MODE"] = "1"
        app.launchArguments = ["--demo", compact ? "--compact" : "--reference-wide", "--reference-date", "2026-11-04T16:16:00Z"]
        app.launch()
        defer { app.terminate() }
        let dashboard = app.windows["dashboard"]
        if !dashboard.waitForExistence(timeout: 2) {
            app.menuBars.menuBarItems["Window"].click()
            app.menuBars.menuBarItems["Window"].menuItems["AI Token Scrooge"].click()
        }
        let running = try XCTUnwrap(NSRunningApplication.runningApplications(withBundleIdentifier: "com.lancelarsen.AITokenScrooge")
            .max { ($0.launchDate ?? .distantPast) < ($1.launchDate ?? .distantPast) })
        running.activate(options: [.activateIgnoringOtherApps])
        let header = dashboard.coordinate(withNormalizedOffset: CGVector(dx: 0.06, dy: 0.08))
        header.click(); header.hover()
        if compact {
            let sort = dashboard.buttons["Custom Order"]
            let offset = sort.frame.minY - (dashboard.frame.minY + 200)
            dashboard.scrollBars.firstMatch.scroll(byDeltaX: 0, deltaY: -offset)
            let mute = dashboard.buttons["Disable Alerts for Codex · 5-Hour"].firstMatch
            XCTAssertTrue(mute.isHittable)
            mute.click()
        }
        let marker = dashboard.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "\(severity) Alert Threshold")).firstMatch
        XCTAssertTrue(marker.waitForExistence(timeout: 5))
        if !marker.isHittable { dashboard.scrollBars.firstMatch.scroll(byDeltaX: 0, deltaY: -250) }
        XCTAssertTrue(marker.isHittable)
        let info = dashboard.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Info Alert Threshold")).firstMatch
        let critical = dashboard.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Critical Alert Threshold")).firstMatch
        let initialX = marker.frame.midX
        let infoX = info.frame.midX, criticalX = critical.frame.midX
        let span = (criticalX - infoX) / 0.4
        let dragDistance: CGFloat = compact ? span * 0.04 : 40
        let expectedRemaining = (initialRemaining - dragDistance / span * 100).rounded()
        let initialWindows = Set(Self.visibleWindows(for: running.processIdentifier).keys)
        func popup() -> (key: CGWindowID, value: CGRect)? {
            Self.visibleWindows(for: running.processIdentifier).first {
                !initialWindows.contains($0.key) && $0.value.width >= 150 && $0.value.width <= 420
                    && $0.value.height >= 40 && $0.value.height < 100
            }
        }
        func waitForPopup() throws -> (key: CGWindowID, value: CGRect) {
            let appeared = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in popup() != nil }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [appeared], timeout: 3), .completed)
            return try XCTUnwrap(popup())
        }
        marker.hover()
        let first = try waitForPopup()
        XCTAssertTrue(dashboard.frame.contains(first.value))
        XCTAssertEqual(first.value.maxY, marker.frame.minY - 2, accuracy: 2,
            "The readout belongs above the bar with the Windows two-point anchor gap")
        let origin = marker.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        // An opt-in longer hold allows an owned-window capture of the native
        // gesture without changing the runner's screen-capture permissions.
        let captureHeld = compact && ProcessInfo.processInfo.environment["SCROOGE_CAPTURE_HELD_THRESHOLD"] == "1"
        if captureHeld { print("SCROOGE_HELD_THRESHOLD_READY") }
        origin.click(forDuration: 0.1, thenDragTo: origin.withOffset(CGVector(dx: dragDistance, dy: 0)), withVelocity: .slow, thenHoldForDuration: captureHeld ? 20 : 0.3)
        XCTAssertEqual(marker.frame.midX, initialX + (initialRemaining - expectedRemaining) / 100 * span, accuracy: 1)
        if severity != "Info" { XCTAssertEqual(info.frame.midX, infoX, accuracy: 1, "Dragging another marker must leave Info unchanged") }
        if severity != "Critical" { XCTAssertEqual(critical.frame.midX, criticalX, accuracy: 1, "Dragging another marker must leave Critical unchanged") }
        marker.hover()
        let dragged = try waitForPopup()
        XCTAssertTrue(dashboard.frame.contains(dragged.value), "Dragged feedback must remain inside the dashboard")
        XCTAssertEqual(dragged.value.minY, first.value.minY, accuracy: 1,
            "Changing the threshold must retain the readout's initial top")
        let screen = CGDisplayBounds(CGMainDisplayID())
        guard screen.contains(dragged.value) else { throw XCTSkip("Owned popup is on a secondary display; do not crop another display") }
        let shot = XCUIScreen.main.screenshot().image
        let pixels = try XCTUnwrap(shot.cgImage(forProposedRect: nil, context: nil, hints: nil))
        let rect = dragged.value.offsetBy(dx: -screen.minX, dy: -screen.minY)
            .applying(CGAffineTransform(scaleX: CGFloat(pixels.width) / screen.width, y: CGFloat(pixels.height) / screen.height))
        let crop = try XCTUnwrap(pixels.cropping(to: rect.integral))
        let recognition = VNRecognizeTextRequest()
        recognition.recognitionLevel = .accurate
        recognition.recognitionLanguages = ["en-US"]
        try VNImageRequestHandler(cgImage: crop).perform([recognition])
        let text = recognition.results?.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ") ?? ""
        XCTAssertTrue(text.contains("\(severity) Alert") && text.contains("Left"), text)
        XCTAssertTrue(text.contains("\(Int(expectedRemaining))%"), "The popup must show the current dragged value: \(text)")
        let capture = XCTAttachment(image: NSImage(cgImage: crop, size: dragged.value.size))
        capture.name = "\(severity) threshold readout after native mouse drag"
        capture.lifetime = .keepAlways
        add(capture)
        if compact {
            XCTAssertEqual(dashboard.frame.width, 789, accuracy: 1)
            XCTAssertEqual(dashboard.frame.height, 694, accuracy: 1)
            let fullFrame = XCTAttachment(screenshot: dashboard.screenshot())
            fullFrame.name = "Compact dashboard with dragged Warning readout"
            fullFrame.lifetime = .keepAlways
            add(fullFrame)
            let pointerMarker = XCTAttachment(screenshot: marker.screenshot())
            pointerMarker.name = "Compact Warning marker after pointer selection"
            pointerMarker.lifetime = .keepAlways
            add(pointerMarker)
        }
        marker.click()
        let keyboardStart = marker.frame.midX
        app.typeKey(.leftArrow, modifierFlags: [])
        XCTAssertEqual(marker.frame.midX, keyboardStart - span / 100, accuracy: 1,
            "Pointer selection must focus the same marker for arrow adjustment")
        app.typeKey(.rightArrow, modifierFlags: [])
        XCTAssertEqual(marker.frame.midX, keyboardStart, accuracy: 1)
        if compact {
            let keyboardMarker = XCTAttachment(screenshot: marker.screenshot())
            keyboardMarker.name = "Compact Warning marker after keyboard adjustment"
            keyboardMarker.lifetime = .keepAlways
            add(keyboardMarker)
        }
        app.typeKey(.escape, modifierFlags: [])
        header.hover()
        XCTAssertNil(popup(), "Escape and pointer exit dismiss threshold feedback")
        let usage = dashboard.buttons.matching(NSPredicate(format: "label CONTAINS %@", "38% Used, 62% Left. Open Details")).firstMatch
        usage.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.5)).click()
        XCTAssertTrue(app.staticTexts["38% Used · 62% Left"].waitForExistence(timeout: 5),
            "The space between threshold thumbs must retain the quota-details action")
        app.buttons["Close"].click()
    }

    @MainActor func testQuotaServiceMessageIconHoverAndDetails() throws {
        let app = XCUIApplication()
        app.launchEnvironment["SCROOGE_TEST_MODE"] = "1"
        app.launchArguments = ["--demo", "--reference-wide", "--scenario", "permission"]
        app.launch()
        defer { app.terminate() }
        let dashboard = app.windows["dashboard"]
        if !dashboard.waitForExistence(timeout: 2) {
            let menu = app.menuBars.menuBarItems["Window"]
            menu.click(); menu.menuItems["AI Token Scrooge"].click()
        }
        app.activate()
        let warning = app.buttons["quotaMessage-demo-0-codex/primary"]
        XCTAssertTrue(warning.waitForExistence(timeout: 10))
        let title = app.buttons["Codex · 5-Hour. Open Details"].firstMatch
        XCTAssertLessThanOrEqual(warning.frame.maxX, title.frame.minX)
        XCTAssertTrue(app.buttons["quotaMessage-demo-1-copilot/monthly"].exists)
        XCTAssertTrue(app.buttons["quotaMessage-demo-3-session"].exists)
        XCTAssertFalse(app.staticTexts["PermissionRequired: Demo: billing read access is unavailable."].exists,
                       "Service messages must not take up space below the quota title")
        let header = dashboard.coordinate(withNormalizedOffset: CGVector(dx: 0.06, dy: 0.12))
        header.click()
        let owner = try XCTUnwrap(NSRunningApplication.runningApplications(withBundleIdentifier: "com.lancelarsen.AITokenScrooge")
            .max { ($0.launchDate ?? .distantPast) < ($1.launchDate ?? .distantPast) }).processIdentifier
        let initial = Set(Self.visibleWindows(for: owner).keys)
        warning.hover()
        func popup() -> CGRect? { Self.visibleWindows(for: owner).first { !initial.contains($0.key) }?.value }
        let appeared = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in popup() != nil }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [appeared], timeout: 3), .completed)
        let panel = try XCTUnwrap(popup())
        XCTAssertTrue(dashboard.frame.contains(panel))
        let screen = CGDisplayBounds(CGMainDisplayID())
        let image = XCUIScreen.main.screenshot().image
        let pixels = try XCTUnwrap(image.cgImage(forProposedRect: nil, context: nil, hints: nil))
        let bounds = panel.offsetBy(dx: -screen.minX, dy: -screen.minY)
            .applying(CGAffineTransform(scaleX: CGFloat(pixels.width) / screen.width, y: CGFloat(pixels.height) / screen.height))
        let crop = try XCTUnwrap(pixels.cropping(to: bounds.integral))
        let recognition = VNRecognizeTextRequest()
        recognition.recognitionLevel = .accurate
        try VNImageRequestHandler(cgImage: crop).perform([recognition])
        let text = recognition.results?.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ") ?? ""
        XCTAssertTrue(text.contains("billing") && text.contains("access"), text)
        let attachment = XCTAttachment(image: NSImage(cgImage: crop, size: panel.size))
        attachment.name = "Quota service message at warning icon"
        attachment.lifetime = .keepAlways
        add(attachment)
        warning.click()
        XCTAssertTrue(app.staticTexts["quotaSourceNote"].firstMatch.waitForExistence(timeout: 5))
        app.buttons["Close"].click()
        title.click()
        XCTAssertTrue(app.staticTexts["quotaSourceNote"].firstMatch.waitForExistence(timeout: 5))
        app.buttons["Close"].click()
        app.terminate()
        app.launchArguments = ["--demo", "--reference-wide", "--scenario", "healthy"]
        app.launch()
        XCTAssertTrue(app.buttons["Codex · 5-Hour. Open Details"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "quotaMessage-")).count, 0)
    }

    @MainActor func testTimelineResetTooltipContentPlacementAndClickThrough() throws {
        try verifyTimelineTooltip(expiry: false)
    }

    @MainActor func testTimelineExpiryTooltipClampsToEdgeAndOpensAvailableResets() throws {
        try verifyTimelineTooltip(expiry: true)
    }

    @MainActor private func verifyTimelineTooltip(expiry: Bool) throws {
        let app = XCUIApplication()
        app.launchEnvironment["SCROOGE_TEST_MODE"] = "1"
        app.launchArguments = ["--demo", "--compact", "--reference-date", "2026-11-04T16:16:00Z"]
        if expiry { app.launchArguments += ["--scenario", "edge-tooltips"] }
        app.launch()
        defer { app.terminate() }
        let dashboard = app.windows["dashboard"]
        if !dashboard.waitForExistence(timeout: 2) {
            let menu = app.menuBars.menuBarItems["Window"]
            menu.click()
            menu.menuItems["AI Token Scrooge"].click()
        }
        app.activate()
        let header = dashboard.coordinate(withNormalizedOffset: CGVector(dx: 0.06, dy: 0.12))
        header.click()
        header.hover()
        let owner = try XCTUnwrap(NSRunningApplication.runningApplications(withBundleIdentifier: "com.lancelarsen.AITokenScrooge")
            .max { ($0.launchDate ?? .distantPast) < ($1.launchDate ?? .distantPast) }).processIdentifier
        let initialWindows = Set(Self.visibleWindows(for: owner).keys)
        let candidates = dashboard.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label BEGINSWITH %@",
            expiry ? "timeline-expiry-" : "timeline-refresh-", "OpenAI,")).allElementsBoundByIndex
            .filter { $0.isHittable && $0.frame.width < 70 && $0.frame.height >= 70 && dashboard.frame.contains($0.frame) }
        let event = try XCTUnwrap(candidates.max { $0.frame.maxX < $1.frame.maxX }, "A visible right-side reset event is required")
        event.hover()
        func floatingPanel() -> (key: CGWindowID, value: CGRect)? {
            Self.visibleWindows(for: owner).first { !initialWindows.contains($0.key) && $0.value.width <= 450 }
        }
        let appeared = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in floatingPanel() != nil }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [appeared], timeout: 3), .completed)
        let panel = try XCTUnwrap(floatingPanel())
        XCTAssertTrue(dashboard.frame.contains(panel.value))
        XCTAssertLessThanOrEqual(panel.value.width, 320)
        if expiry {
            XCTAssertGreaterThan(event.frame.midX + panel.value.width / 2, dashboard.frame.maxX - 8,
                "The fixture must actually force right-edge clamping")
            XCTAssertEqual(panel.value.maxX, dashboard.frame.maxX - 8, accuracy: 1)
        }
        let screen = CGDisplayBounds(CGMainDisplayID())
        let image = XCUIScreen.main.screenshot().image
        let pixels = try XCTUnwrap(image.cgImage(forProposedRect: nil, context: nil, hints: nil))
        let cropBounds = panel.value.offsetBy(dx: -screen.minX, dy: -screen.minY)
            .applying(CGAffineTransform(scaleX: CGFloat(pixels.width) / screen.width, y: CGFloat(pixels.height) / screen.height))
        let crop = try XCTUnwrap(pixels.cropping(to: cropBounds.integral))
        let recognition = VNRecognizeTextRequest()
        recognition.recognitionLevel = .accurate
        recognition.recognitionLanguages = ["en-US"]
        try VNImageRequestHandler(cgImage: crop).perform([recognition])
        let text = recognition.results?.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ") ?? ""
        XCTAssertTrue((text.contains("OpenAI") || text.contains("OpenAl")) && text.contains("Nov"), text)
        XCTAssertTrue(text.contains(expiry ? "Earned Reset Expires" : "Quota Refresh"), text)
        XCTAssertNotNil(text.range(of: #"[0-9]+[dhm]"#, options: .regularExpression), "A styled remaining-time label must be visible: \(text)")
        let attachment = XCTAttachment(image: NSImage(cgImage: crop, size: panel.value.size))
        attachment.name = expiry ? "Expiry tooltip clamped at compact right edge" : "Reset event tooltip at compact right side"
        attachment.lifetime = .keepAlways
        add(attachment)
        header.hover()
        XCTAssertNil(Self.visibleWindows(for: owner)[panel.key], "Pointer exit hides reset details")
        event.hover()
        let reopened = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in floatingPanel() != nil }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [reopened], timeout: 3), .completed)
        let reopenedPanel = try XCTUnwrap(floatingPanel())
        event.click()
        XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 5), "The tooltip must not intercept the reset event's details action")
        if expiry {
            XCTAssertTrue(app.staticTexts["Available Resets"].exists)
            XCTAssertTrue(app.staticTexts["resetCredit-demo-edge-expiry"].exists,
                "The expiry must open the same account's reported reset credit")
        } else {
            let work = event.label.contains(", Pro,")
            let account = work ? "OpenAI / Work · Pro" : "OpenAI / Personal · Plus"
            XCTAssertTrue(app.staticTexts[account].exists)
            let weekly = text.contains("Weekly")
            let usage = work ? (weekly ? "58% Used · 42% Left" : "19% Used · 81% Left") :
                (weekly ? "74% Used · 26% Left" : "38% Used · 62% Left")
            XCTAssertTrue(app.staticTexts[usage].exists, "The hovered event must open its matching quota")
        }
        XCTAssertNil(Self.visibleWindows(for: owner)[reopenedPanel.key], "Clicking an event hides its tooltip")
        app.buttons["Close"].click()
    }

    @MainActor func testHistoryHoverShowsDetailsAndDismissesOnExit() throws {
        try verifyHistoryInteraction(keyboardEntry: false)
    }

    @MainActor func testHistoryTabEntryFromLaunch() throws {
        try verifyHistoryInteraction(keyboardEntry: true)
    }

    @MainActor private func verifyHistoryInteraction(keyboardEntry: Bool) throws {
        let app = XCUIApplication()
        app.launchEnvironment["SCROOGE_TEST_MODE"] = "1"
        app.launchArguments = ["--demo", "--compact", "--reference-date", "2026-11-04T16:16:00Z"]
        app.launch()
        defer { app.terminate() }
        let dashboard = app.windows["dashboard"]
        if !dashboard.waitForExistence(timeout: 2) {
            let windowMenu = app.menuBars.menuBarItems["Window"]
            windowMenu.click()
            windowMenu.menuItems["AI Token Scrooge"].click()
        }
        let elements = dashboard.descendants(matching: .any)
        let axis = elements.matching(NSPredicate(format: "label BEGINSWITH %@", "History axis:")).firstMatch
        XCTAssertTrue(axis.waitForExistence(timeout: 5))
        app.activate()
        if !keyboardEntry { dashboard.coordinate(withNormalizedOffset: CGVector(dx: 0.06, dy: 0.12)).click() }
        // The first few points after midnight are in the plotted past,
        // left of today's stacked event badges (which have their own tooltip).
        let sample = axis.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0.57))
            .withOffset(CGVector(dx: 3, dy: 0))
        let running = try XCTUnwrap(NSRunningApplication.runningApplications(withBundleIdentifier: "com.lancelarsen.AITokenScrooge")
            .max { ($0.launchDate ?? .distantPast) < ($1.launchDate ?? .distantPast) })
        let owner = running.processIdentifier
        running.activate(options: [.activateIgnoringOtherApps])
        let activated = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            NSWorkspace.shared.frontmostApplication?.processIdentifier == owner
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [activated], timeout: 3), .completed)
        let header = dashboard.coordinate(withNormalizedOffset: CGVector(dx: 0.06, dy: 0.12))
        let initialWindows = Set(Self.visibleWindows(for: owner).keys)
        func tooltipFrame() -> CGRect? {
            if keyboardEntry {
                return Self.visibleWindows(for: owner).values.first {
                    $0.height >= 60 && $0.width <= 450 && dashboard.frame.contains($0)
                }
            }
            return Self.visibleWindows(for: owner).first { !initialWindows.contains($0.key) }?.value
        }
        func waitForPopup() throws -> CGRect {
            let appeared = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                tooltipFrame() != nil
            }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [appeared], timeout: 3), .completed)
            return try XCTUnwrap(tooltipFrame())
        }
        if keyboardEntry {
            header.hover()
            for _ in 0..<40 {
                if let frame = tooltipFrame(), frame.height >= 60, dashboard.frame.contains(frame) { break }
                app.typeKey(.tab, modifierFlags: [])
                RunLoop.current.run(until: Date().addingTimeInterval(0.15))
                if let frame = tooltipFrame(), frame.height >= 60, dashboard.frame.contains(frame) { break }
            }
        } else { sample.hover() }
        let panel = try waitForPopup()
        XCTAssertTrue(dashboard.frame.contains(panel))

        // Borderless, nonactivating panels aren't in XCTest's window tree.
        // Verify their visible content and attach only the demo panel's pixels.
        let screen = CGDisplayBounds(CGMainDisplayID())
        let capture = XCUIScreen.main.screenshot().image
        let pixels = try XCTUnwrap(capture.cgImage(forProposedRect: nil, context: nil, hints: nil))
        let bounds = panel.offsetBy(dx: -screen.minX, dy: -screen.minY)
            .applying(CGAffineTransform(scaleX: CGFloat(pixels.width) / screen.width,
                                       y: CGFloat(pixels.height) / screen.height))
        let crop = try XCTUnwrap(pixels.cropping(to: bounds.integral))
        let recognition = VNRecognizeTextRequest()
        recognition.recognitionLevel = .fast
        recognition.recognitionLanguages = ["en-US"]
        try VNImageRequestHandler(cgImage: crop).perform([recognition])
        let text = recognition.results?.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ") ?? ""
        XCTAssertTrue((text.contains("OpenAI") || (keyboardEntry && text.contains("Claude"))) && text.contains("Weekly") && text.contains("% Used"), text)
        let screenshot = XCTAttachment(image: NSImage(cgImage: crop, size: panel.size))
        screenshot.name = keyboardEntry ? "History sample reached with Tab" : "History sample at pointer"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        if keyboardEntry { app.typeKey(.escape, modifierFlags: []) }
        header.hover()
        XCTAssertNil(tooltipFrame())
        sample.click()
        header.hover()
        XCTAssertNotNil(tooltipFrame(), "A clicked sample stays pinned on pointer exit")
        app.typeKey(.escape, modifierFlags: [])
        XCTAssertNil(tooltipFrame(), "Escape dismisses the focused chart sample")
        app.typeKey(.leftArrow, modifierFlags: [])
        XCTAssertTrue(dashboard.frame.contains(try waitForPopup()), "Arrow navigation restores sample details")
        app.typeKey(.tab, modifierFlags: [.shift])
        XCTAssertLessThan(tooltipFrame()?.height ?? 0, panel.height, "Leaving chart focus clears the history readout, allowing the next control’s tooltip")
        app.typeKey(.tab, modifierFlags: [])
        let reenteredPanel = try waitForPopup()
        XCTAssertTrue(dashboard.frame.contains(reenteredPanel))
        XCTAssertGreaterThanOrEqual(reenteredPanel.height, panel.height, "Tab re-entry restores the history readout")
        sample.scroll(byDeltaX: 0, deltaY: 80)
        header.hover()
        XCTAssertNil(tooltipFrame(), "A wheel gesture releases a pinned sample")
        sample.hover()
        XCTAssertTrue(dashboard.frame.contains(try waitForPopup()), "The next hover must select a fresh sample")
    }

    private static func visibleWindows(for pid: pid_t) -> [CGWindowID: CGRect] {
        let windows = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] ?? []
        var result: [CGWindowID: CGRect] = [:]
        for window in windows {
            guard window[kCGWindowOwnerPID as String] as? pid_t == pid,
                  let id = window[kCGWindowNumber as String] as? CGWindowID,
                  let bounds = window[kCGWindowBounds as String] as? NSDictionary,
                  let rect = CGRect(dictionaryRepresentation: bounds) else { continue }
            result[id] = rect
        }
        return result
    }

    private func seedPausedAccount(at url: URL, withQuota: Bool = false) {
        var database: OpaquePointer?
        let result = sqlite3_open(url.path, &database)
        defer { sqlite3_close(database) }
        XCTAssertEqual(result, SQLITE_OK)
        // A saved account without credentials lets the test enter reconnect without contacting a provider.
        let sql = """
            CREATE TABLE state (id INTEGER PRIMARY KEY, payload BLOB NOT NULL);
            INSERT INTO state VALUES (1, '{"accounts":[{"id":"sample","provider":"GitHub Copilot",
                "nickname":"Work","subject":"sample","scope":"personal","enabled":\(withQuota ? "true" : "false"),"unit":"credits",
                "credentialID":"8825F897-08B6-441C-BBCE-F58CA0C9BC76","pollingMinutes":2,
                "generation":"EC88AFF0-5D3A-49C1-A7D1-19887D761FB6"}],"snapshots":\(withQuota ? #"{"sample":{"accountID":"sample","subject":"sample","scope":"personal","observedAt":800000000,"health":"stale","windows":[{"id":"monthly","name":"AI Credits · Monthly","unit":"credits","used":25,"limit":100,"allowanceSource":"provider"}]}}"# : "{}")}');
            """
        XCTAssertEqual(sqlite3_exec(database, sql, nil, nil, nil), SQLITE_OK)
    }
}

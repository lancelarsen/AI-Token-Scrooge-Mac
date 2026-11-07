import SQLite3
import Vision
import XCTest

final class DashboardUITests: XCTestCase {
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
        selector.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.5)).click()
        XCTAssertTrue(app.buttons["Show OpenAI / Personal · Plus · Timeline"].exists, "The selector margin must toggle account history")
        selector.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.5)).click()
        XCTAssertTrue(app.buttons["Hide OpenAI / Personal · Plus · Timeline"].exists)
        exit.click()
        XCTAssertTrue(app.buttons["exploreDemoButton"].waitForExistence(timeout: 5))
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
        XCTAssertEqual(app.buttons["Close"].frame.width, 142, accuracy: 1, "Windows reserves half the footer for a single close action")
        app.buttons["Close"].click()
        app.buttons["Unknown Request Limit. Open Details"].firstMatch.click()
        let unavailable = app.staticTexts["50 Used · Limit Unavailable"].firstMatch
        XCTAssertTrue(unavailable.waitForExistence(timeout: 5))
        XCTAssertTrue(app.sheets.firstMatch.frame.contains(unavailable.frame))
        app.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(unavailable.waitForNonExistence(timeout: 5))
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

    @MainActor func testColorPickerKeyboardModeAndExactSwatch() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let app = XCUIApplication()
        app.launchEnvironment["SCROOGE_TEST_MODE"] = "1"
        app.launchArguments = ["--demo", "--data-dir", directory.path]
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

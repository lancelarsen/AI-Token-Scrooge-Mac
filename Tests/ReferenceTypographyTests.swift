import AppKit
import CoreText
import SwiftUI
import XCTest
@testable import AITokenScrooge

final class ReferenceTypographyTests: XCTestCase {
    @MainActor func testHelpAndResetTooltipsMatchNativeWindowsBounds() throws {
        let text = "OpenAI / Personal · Plus\nShow or Hide History, Resets and Refreshes"
        let width = ReferenceHelpTooltip.width(for: text, availableWidth: 700)
        let plain = NSHostingView(rootView: ReferenceHelpTooltip(text: text, width: width))
        // Native Windows run 42364265780: 35-point context + 22 border/padding.
        XCTAssertEqual(plain.fittingSize, CGSize(width: 278, height: 57))
        let formatter = ISO8601DateFormatter()
        let date = try XCTUnwrap(formatter.date(from: "2026-11-09T10:31:00Z"))
        let now = try XCTUnwrap(formatter.date(from: "2026-11-07T10:31:01Z"))
        let content = ResetTooltipContent(context: "OpenAI / Personal · Plus\nQuota Refresh · Codex · Weekly",
                                          date: date, now: now, zone: TimeZone(identifier: "America/Chicago")!)
        let reset = NSHostingView(rootView: ReferenceResetTooltip(content: content, width: content.width(available: 700)))
        XCTAssertEqual(reset.fittingSize, CGSize(width: 209, height: 110))
        // The separately measured countdown keeps its 24-point fallback line.
        let countdown = NSHostingView(rootView: ResetCountdownText(date: date, now: now, zone: content.zone))
        XCTAssertEqual(countdown.fittingSize.height, 43, accuracy: 0.5)
    }

    @MainActor func testWrappedPollingTooltipMatchesNativeWindowsDesiredWidth() throws {
        let text = "How often Scrooge automatically checks this account for updated usage, from 1 to 30 minutes. Shorter intervals show changes sooner; longer intervals make fewer requests. Changes save automatically."
        let width = ReferenceHelpTooltip.width(for: text, availableWidth: 700)
        // Native Windows run 42366495646: 284×87 text, 314×109 surface.
        XCTAssertEqual(width, 314)
        let renderer = ImageRenderer(content: ReferenceHelpTooltip(text: text, width: width))
        renderer.scale = 1
        let image = NSBitmapImageRep(cgImage: try XCTUnwrap(renderer.cgImage))
        XCTAssertEqual(image.pixelsWide, 314)
        XCTAssertEqual(image.pixelsHigh, 109)
        let rows = inkRows(image, minimum: 0.65)
        XCTAssertEqual(rows.filter { !rows.contains($0 - 1) }.count, 5,
                       "All five wrapped lines remain visible after desired-width sizing")
        XCTAssertGreaterThan(try XCTUnwrap(rows.last), 90)
        for available in [0.0, 20, 160, 240] {
            let constrained = ReferenceHelpTooltip.width(for: text, availableWidth: available)
            XCTAssertGreaterThanOrEqual(constrained, 0)
            XCTAssertLessThanOrEqual(constrained, available)
        }
    }

    @MainActor func testClassicLabelsMatchCapturedWindowsLineBlocks() throws {
        // Native Windows run 42367678432: settings description 13/18,
        // dashboard tagline 16/22, and a 649-wide two-line description 13/35.
        for (text, size, width, height) in [
            ("Warning and critical levels are adjusted directly on the dashboard bars.", 13.0, 649.0, 18.0),
            ("Never Waste a Token! Never Miss a Reset!", 16.0, 600.0, 22.0),
            ("Choose how long to keep recorded usage and alerts. Shortening this period removes older records; increasing it cannot restore deleted records.", 13.0, 649.0, 35.0),
            // Native connection forms, Windows run 42374233894.
            ("Sign in through OpenAI in your browser. Scrooge keeps this account in its own protected Codex profile and only reads usage limits.", 14.0, 550.0, 38.0),
            ("Advanced connection: use a fine-grained token with Plan read permission for personal billing. Organization billing requires authorized administration access. Your token stays protected on this PC.", 14.0, 534.0, 56.0)
        ] {
            let host = NSHostingView(rootView: Text(text).font(.reference(size: size))
                .referenceClassicLineMetrics(size: size).frame(width: width)
                .fixedSize(horizontal: false, vertical: true))
            XCTAssertEqual(host.fittingSize.height, height)
        }
    }

    @MainActor func testClassicSixteenPointMultilineRenderingRetainsDescenders() throws {
        for (count, height) in [(1, 22), (2, 43), (4, 86), (12, 256)] {
            let text = Array(repeating: "Hg", count: count).joined(separator: "\n")
            let renderer = ImageRenderer(content: Text(text).font(.reference(size: 16))
                .referenceClassicLineMetrics(size: 16).foregroundStyle(.white)
                .frame(width: 100, alignment: .leading).background(.black))
            renderer.scale = 1
            let image = NSBitmapImageRep(cgImage: try XCTUnwrap(renderer.cgImage))
            XCTAssertEqual(image.pixelsHigh, height)
            let rows = inkRows(image)
            XCTAssertEqual(rows.filter { !rows.contains($0 - 1) }.count, count)
            XCTAssertGreaterThan(try XCTUnwrap(rows.last), height - 6)
            XCTAssertLessThan(try XCTUnwrap(rows.last), height)
        }
    }

    @MainActor func testQuietHoursRangeMatchesNativeWindowsSummaryHeight() {
        let host = NSHostingView(rootView: QuietHoursControl(start: .constant(0), end: .constant(8)).frame(width: 649))
        // Windows run 42369557174: 94-point range, four-point gap, 22-point summary.
        XCTAssertEqual(host.fittingSize.height, 120)
    }

    @MainActor func testNativeFractionalLineMetricsRetainLongTextAcrossFontSizes() throws {
        let heights: [(CGFloat, [Int])] = [(14, [19, 38, 75, 224, 373]),
                                           (16, [22, 43, 86, 256, 426]),
                                           (22, [30, 59, 118, 352, 586])]
        for (size, expected) in heights {
            for (count, height) in zip([1, 2, 4, 12, 20], expected) {
                let text = Array(repeating: "Hg", count: count).joined(separator: "\n")
                let content = Text(text).font(ReferenceTypography.nativeTextFont(size: size))
                    .referenceNativeTextLineMetrics(size: size).foregroundStyle(.white)
                    .frame(width: 100, alignment: .leading).background(.black)
                XCTAssertEqual(NSHostingView(rootView: content).fittingSize.height, CGFloat(height))
                let renderer = ImageRenderer(content: content)
                renderer.scale = 1
                let image = NSBitmapImageRep(cgImage: try XCTUnwrap(renderer.cgImage))
                XCTAssertEqual(image.pixelsHigh, height)
                let rows = inkRows(image)
                XCTAssertEqual(rows.filter { !rows.contains($0 - 1) }.count, count,
                               "Every line must remain visible at size \(size)")
            }
        }
    }

    @MainActor func testWrappedDialogTextMatchesCapturedNativeTitleAndParagraph() throws {
        // Actual Windows run42404838337: five-line22-point title147 high,
        // four-line14-point regular body75 high, with these exact widths.
        let nickname = "Personal development and research across multiple workspaces with shared subscriptions, independent production environments, separate evaluation projects, and several collaborative engineering teams"
        let title = NSHostingView(rootView: Text("OpenAI / " + nickname + " · Plus")
            .font(Theme.dialogTitleFont).referenceNativeTextLineMetrics(size: 22).frame(width: 478))
        XCTAssertEqual(title.fittingSize, CGSize(width: 478, height: 147))
        let paragraph = "OpenAI / " + nickname + " · Plus: 2 reported available"
        let body = DialogBodyText(paragraph).frame(width: 482)
        XCTAssertEqual(NSHostingView(rootView: body).fittingSize, CGSize(width: 482, height: 75))
        XCTAssertNil(Format.dialogLine(paragraph).label, "Windows does not emphasize prefixes45 characters or longer")
        func pixels<V: View>(_ content: V) throws -> Data {
            let renderer = ImageRenderer(content: content.foregroundStyle(Theme.dialogText).background(.black))
            renderer.scale = 1
            let image = NSBitmapImageRep(cgImage: try XCTUnwrap(renderer.cgImage))
            return try XCTUnwrap(image.representation(using: .png, properties: [:]))
        }
        let regular = Text(verbatim: paragraph).font(Theme.dialogBodyFont)
            .referenceNativeTextLineMetrics(size: 14).frame(width: 482, alignment: .leading)
        XCTAssertEqual(try pixels(body), try pixels(regular), "The captured long account paragraph is entirely regular weight")
        let action = NSHostingView(rootView: DialogActionLabel(title: "First line\nSecond line\nThird line").frame(width: 370))
        XCTAssertEqual(action.fittingSize.height, 56)
    }

    @MainActor func testDialogAutomaticWidthsMatchNativeWrappedTextAndKeepFixedForms() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = AppStore(database: try LocalStore(url: directory.appendingPathComponent("width.db")))
        store.enterDemo()
        await store.waitForPendingMutations()
        let account = try XCTUnwrap(store.state.accounts.first)
        let nickname = "Personal development and research across multiple workspaces with shared subscriptions, independent production environments, separate evaluation projects, and several collaborative engineering teams"
        store.edit { state in
            if let index = state.accounts.firstIndex(where: { $0.id == account.id }) { state.accounts[index].nickname = nickname }
        }
        await store.waitForPendingMutations()
        // Native run42404838337: text columns478/482,24-point padding,
        // one-point border and two equal footer columns235/237 points wide.
        for (window, expected) in [(Optional("codex/primary"), CGSize(width: 528, height: 538)),
                                   (nil, CGSize(width: 532, height: 341))] {
            let host = NSHostingView(rootView: AccountUsageDialog(accountID: account.id, windowID: window, close: {})
                .environment(store))
            XCTAssertEqual(host.fittingSize, expected)
        }
        XCTAssertEqual(ReferenceTypography.dialogTextWidth("OpenAI / " + nickname + " · Plus", size: 22, semibold: true), 478)
        XCTAssertEqual(ReferenceTypography.dialogTextWidth("OpenAI / " + nickname + " · Plus: 2 reported available"), 482)
        let chooser = NSHostingView(rootView: ConnectionView(original: nil).environment(store))
        XCTAssertEqual(chooser.fittingSize, CGSize(width: 320, height: 431))
        let color = NSHostingView(rootView: DetailsDialog(title: "Add Line Color", width: 362, closeTitle: "Cancel",
            tabToFooter: true, primaryTitle: "Add Color", primaryAction: {}, close: {}) {
                InlineLineColorEditor(color: .constant(Color(hex: "#D587A5")), reveal: { _ in }).frame(width: 312)
            })
        XCTAssertEqual(color.fittingSize, CGSize(width: 362, height: 605))
    }

    @MainActor func testColorEditorMatchesNativeWindowsContentExtent() {
        // Native open-menu run42386108887: 14-point Variable Text yields
        // RGB26×19 and HSV27×19, unlike AppKit's13-point system-menu default.
        let menuFont = ReferenceTypography.nativeMenuFont()
        for (text, width) in [("RGB", 26.0), ("HSV", 27.0)] {
            let size = (text as NSString).size(withAttributes: [.font: menuFont])
            XCTAssertEqual(ceil(size.width), width)
            XCTAssertEqual(size.height, 19, accuracy: 0.5)
        }
        let host = NSHostingView(rootView: InlineLineColorEditor(color: .constant(Color(hex: "#D587A5")), reveal: { _ in })
            .frame(width: 312))
        // Run42376211522: 312×420 scroll viewport with 85.02024291497976%
        // vertical view size, independently establishing 494 points of content.
        XCTAssertEqual(host.fittingSize, CGSize(width: 312, height: 494))
    }

    @MainActor func testSettingsPickerTextsMatchCapturedWindowsMenuMetrics() {
        // Actual open ComboBox text bounds from native run42388250473.
        let samples: [(String, CGFloat)] = [("Info", 25), ("Warning", 53), ("Critical", 43),
                                           ("Days", 30), ("Hours", 37),
                                           ("(UTC-06:00) Central Time (US & Canada)", 249)]
        for (text, width) in samples {
            let host = NSHostingView(rootView: Text(text).font(ReferenceTypography.nativeTextFont()))
            XCTAssertEqual(host.fittingSize.width, width, accuracy: 0.5)
            XCTAssertEqual(host.fittingSize.height, 19, accuracy: 0.5)
        }
    }

    @MainActor func testConnectionStatusRetainsNativeMultilineMetricsAndEmptyRow() {
        // Native run42396166221: the advanced connection's three-line classic
        // Segoe14 Label is534x56. Status and explanation share that Label style.
        let text = "Advanced connection: use a fine-grained token with Plan read permission for personal billing. Organization billing requires authorized administration access. Your token stays protected on this PC."
        let wrapped = NSHostingView(rootView: ConnectionStatusLine(text: text).frame(width: 534))
        XCTAssertEqual(wrapped.fittingSize, CGSize(width: 534, height: 56))
        for (message, height) in [("", 19.0), ("Waiting for sign-in", 19.0),
                                  ("One line\nAnother line", 38.0),
                                  ("One line\nAnother line\nThird line\nFourth line", 75.0)] {
            let host = NSHostingView(rootView: ConnectionStatusLine(text: message).frame(width: 534))
            XCTAssertEqual(host.fittingSize.height, height, accuracy: 0.5)
        }
    }

    @MainActor func testSoundChoicesMatchCapturedWindowsRadioTargets() {
        for title in ["Duck Sounds", "Classic Chimes"] {
            let host = NSHostingView(rootView: ReferenceRadioChoice(title: title, selected: false, select: {}))
            // Native run 42370975807: both radio targets have the 120×32 minimum.
            XCTAssertEqual(host.fittingSize, CGSize(width: 120, height: 32))
        }
    }

    @MainActor func testQuietHoursDisabledTimeTextMatchesWindows() throws {
        for enabled in [true, false] {
            let renderer = ImageRenderer(content: QuietHoursControl(start: .constant(0), end: .constant(8))
                .frame(width: 649).disabled(!enabled).opacity(enabled ? 1 : 0.5)
                .background(Color(hex: "#1C1E24")).environment(\.colorScheme, .dark))
            renderer.scale = 1
            let image = NSBitmapImageRep(cgImage: try XCTUnwrap(renderer.cgImage))
            var brightest = [0, 0, 0]
            // Independent native 12 AM label rectangle, translated to the range.
            for y in 0..<32 { for x in 284..<364 {
                var pixel = [Int](repeating: 0, count: image.samplesPerPixel)
                image.getPixel(&pixel, atX: x, y: y)
                let rgb = Array((image.bitmapFormat.contains(.alphaFirst) ? pixel.dropFirst() : pixel[...]).prefix(3))
                if rgb.reduce(0, +) > brightest.reduce(0, +) { brightest = rgb }
            } }
            let expected = enabled ? [242, 241, 245] : [135, 135, 140]
            for channel in 0..<3 {
                XCTAssertEqual(brightest[channel], expected[channel], accuracy: 1,
                               "Native time-label ink must receive one disabled fade, not two")
            }
        }
    }

    @MainActor func testNativeVariableFontMatchesCapturedWindowsVersionAndAxes() throws {
        let font = ReferenceTypography.nativeMenuFont()
        // Installed file from Windows run42396166221; captured22-point title.
        XCTAssertEqual(CTFontCopyName(font as CTFont, kCTFontVersionNameKey) as String?, "Version 2.03")
        XCTAssertEqual(font.pointSize, 14)
        let large = ReferenceTypography.nativeMenuFont(size: 16)
        let axes = try XCTUnwrap(CTFontCopyVariation(large as CTFont) as? [NSNumber: NSNumber])
        XCTAssertEqual(axes[0x6F70737A]?.doubleValue, 12)
        let title = NSHostingView(rootView: Text("Connect Account")
            .font(ReferenceTypography.nativeTextFont(size: 22, semibold: true)))
        XCTAssertEqual(title.fittingSize, CGSize(width: 172, height: 30))
        let detail = NSHostingView(rootView: DetailLine(label: "Last successful fetch", value: "2026-11-07 11:25:04 -06:00")
            .font(Theme.dialogBodyFont))
        XCTAssertEqual(detail.fittingSize, CGSize(width: 297, height: 19))
    }

    @MainActor func testProviderChoiceTextMatchesNativeWindowsLineBoxes() {
        // Four current provider rows, native Windows run42394008393.
        for (text, width) in [("OpenAI Codex", 103.0), ("GitHub Copilot", 106.0),
                              ("Claude", 49.0), ("Devin", 41.0)] {
            let host = NSHostingView(rootView: Text(text).font(ReferenceTypography.nativeTextFont(size: 16))
                .referenceNativeTextLineMetrics(size: 16))
            XCTAssertEqual(host.fittingSize, CGSize(width: width, height: 22))
        }
    }

    @MainActor func testSpectrumGradientMatchesNativeLogicalPixels() throws {
        // Unobscured spectrum pixels from native Windows run42392328103.
        // Render the actual image through the same interpolation as the view.
        let renderer = ImageRenderer(content: Image(nsImage: try XCTUnwrap(LineColorSpectrum.image))
            .resizable().interpolation(.high).frame(width: 256, height: 256))
        renderer.scale = 1
        let image = NSBitmapImageRep(cgImage: try XCTUnwrap(renderer.cgImage))
        for (x, y, expected) in [(16, 16, [255, 106, 16]), (64, 64, [159, 255, 64]),
                                  (128, 128, [128, 255, 255]), (240, 16, [255, 16, 104]),
                                  (128, 240, [240, 255, 255]), (32, 160, [255, 231, 160])] {
            var pixel = [Int](repeating: 0, count: image.samplesPerPixel)
            image.getPixel(&pixel, atX: x, y: y)
            let rgb = Array((image.bitmapFormat.contains(.alphaFirst) ? pixel.dropFirst() : pixel[...]).prefix(3))
            XCTAssertEqual(rgb, expected, "Spectrum pixel at \(x),\(y)")
        }
    }

    @MainActor func testReferenceControlColorsMatchCapturedWindowsThemes() throws {
        // Independent normal-state pixels: dark run 42370975807 and the prior
        // light runner capture 42369557174, both over the same #1C1E24 card.
        for (scheme, center, offFill, sliderRing) in [
            (ColorScheme.dark, [0, 0, 0], [25, 27, 32], [69, 69, 69]),
            (ColorScheme.light, [255, 255, 255], [27, 29, 35], [255, 255, 255])
        ] {
            func check<V: View>(_ view: V, samples: [(Int, Int, [Int])]) throws {
                let renderer = ImageRenderer(content: view.background(Color(hex: "#1C1E24"))
                    .environment(\.colorScheme, scheme))
                renderer.scale = 1
                let image = NSBitmapImageRep(cgImage: try XCTUnwrap(renderer.cgImage))
                for (x, y, expected) in samples {
                    // Compare the captured eight-bit sRGB samples directly;
                    // colorAt's calibrated NSColor conversion changes these values.
                    var samples = [Int](repeating: 0, count: image.samplesPerPixel)
                    image.getPixel(&samples, atX: x, y: y)
                    let actual = Array((image.bitmapFormat.contains(.alphaFirst) ? samples.dropFirst() : samples[...]).prefix(3))
                    for channel in 0..<3 {
                        XCTAssertEqual(actual[channel], expected[channel], accuracy: 1,
                                       "\(scheme) control pixel at \(x),\(y), channel \(channel)")
                    }
                }
            }
            try check(Toggle("", isOn: .constant(true)).toggleStyle(ScroogeSwitchStyle(showsLabel: false)),
                      samples: [(30, 10, center), (10, 10, [129, 112, 207])])
            try check(ReferenceRadioIndicator(selected: true), samples: [(10, 10, center), (3, 10, [169, 144, 237])])
            try check(ReferenceRadioIndicator(selected: false), samples: [(10, 10, offFill)])
            try check(ScroogePercentSlider(value: .constant(65), thumbColor: Theme.accent).frame(width: 525, height: 32),
                      samples: [(330, 16, sliderRing), (338, 16, [195, 173, 248])])
            try check(Toggle("", isOn: .constant(true)).toggleStyle(ScroogeSwitchStyle(showsLabel: false, thumbColor: Color(hex: "#D1BEFF"))),
                      samples: [(30, 10, [209, 190, 255])])
            if scheme == .dark {
                // Actual Tab focus in pinned Windows run42382119965. The
                // outer focus outline adds four points around the32-point body.
                try check(ColorModelFieldSurface(focused: true).frame(width: 120, height: 32).padding(4),
                          samples: [(20, 20, [59, 60, 66]), (6, 20, [76, 194, 255]),
                                    (126, 20, [255, 255, 255]), (64, 0, [255, 255, 255]),
                                    (64, 4, [67, 67, 73]), (123, 20, [62, 63, 68])])
                try check(ColorModelFieldSurface(focused: false).frame(width: 120, height: 32).padding(4),
                          samples: [(20, 20, [47, 48, 54]), (6, 20, [47, 48, 54]), (126, 20, [28, 30, 36])])
                // Native held-pointer captures: hover fill52/53/59 and
                // pressed fill41/42/48; normal/hover share the top highlight.
                try check(ColorModelFieldSurface(focused: false, hovered: true).frame(width: 120, height: 32),
                          samples: [(60, 16, [52, 53, 59]), (60, 0, [55, 56, 61]), (60, 31, [50, 51, 56]),
                                    (0, 16, [50, 51, 56])])
                try check(ColorModelFieldSurface(focused: false, hovered: true, pressed: true).frame(width: 120, height: 32),
                          samples: [(60, 16, [41, 42, 48]), (60, 0, [50, 51, 56])])
                try check(ColorEntryFieldSurface(focused: false, hovered: true).frame(width: 132, height: 32),
                          samples: [(110, 10, [52, 53, 59]), (50, 0, [50, 51, 56]), (50, 31, [154, 155, 158])])
                try check(ColorEntryFieldSurface(focused: true, hovered: true).frame(width: 132, height: 32),
                          samples: [(110, 10, [31, 31, 33]), (50, 0, [50, 51, 56]), (50, 31, [76, 194, 255])])
                // Native clear-button run42391456789: a26x24 inset within
                // the30x32 target; no fill outside it or in the normal state.
                for (hovered, pressed, expected) in [(false, false, [31, 31, 33]),
                                                       (true, false, [44, 44, 46]),
                                                       (true, true, [40, 40, 42])] {
                    try check(ColorEntryClearSurface(hovered: hovered, pressed: pressed)
                        .frame(width: 30, height: 32).background(Color(hex: "#1F1F21")),
                              samples: [(6, 12, expected), (13, 4, expected),
                                        (13, 3, [31, 31, 33]), (27, 16, [31, 31, 33])])
                }
                // Focused native Hex input, run42377781813. The captured
                // Windows default focus accent is independent of app lavender.
                try check(Text("").frame(maxWidth: .infinity).modifier(ColorEntryStyle(focused: true)).frame(width: 132),
                          samples: [(110, 10, [31, 31, 33]), (50, 30, [76, 194, 255]), (50, 31, [76, 194, 255])])
                try check(Text("").frame(maxWidth: .infinity).modifier(ColorEntryStyle()).frame(width: 132),
                          samples: [(110, 10, [47, 48, 54]), (50, 31, [154, 155, 158])])
                // Native color-picker run42376211522: 20-point thumb, white
                // ten-point center and #454545 outer ring.
                XCTAssertEqual(NSHostingView(rootView: ColorBrightnessThumb()).fittingSize, CGSize(width: 20, height: 20))
                try check(ColorBrightnessThumb().background(Color(hex: "#222329")),
                          samples: [(10, 10, [255, 255, 255]), (3, 10, [69, 69, 69]), (10, 0, [34, 35, 41])])
                // Native Tab focus at brightness, run42393295201. The full
                //312-point track receives seven points of outline on each side.
                try check(ColorBrightnessFocusOutline().frame(width: 326, height: 32)
                    .background(Color(hex: "#222329")),
                          samples: [(0, 16, [255, 255, 255]), (1, 16, [255, 255, 255]),
                                    (2, 16, [10, 10, 12]), (3, 16, [34, 35, 41]),
                                    (20, 0, [255, 255, 255]), (20, 2, [10, 10, 12])])
                // Native off/disabled run 42373113228. Windows and CoreGraphics
                // alpha rounding can differ by one eight-bit channel step.
                try check(Toggle("", isOn: .constant(false)).toggleStyle(ScroogeSwitchStyle(showsLabel: false)),
                          samples: [(10, 10, [203, 203, 204]), (30, 10, [25, 27, 32]), (20, 0, [151, 152, 154])])
                let quiet = QuietHoursControl(start: .constant(0), end: .constant(8)).frame(width: 649)
                try check(quiet, samples: [(40, 44, [65, 67, 79]), (420, 44, [169, 144, 237]), (324, 44, [195, 173, 248])])
                // SettingsView already applies this dimming outside the range.
                try check(quiet.disabled(true).opacity(0.5),
                          samples: [(40, 44, [47, 49, 58]), (420, 44, [99, 87, 137]), (324, 44, [112, 102, 142])])
            }
        }
    }

    @MainActor func testHistoryReadoutMatchesCapturedWindowsBounds() {
        let host = NSHostingView(rootView: ReferenceHistoryTooltip(
            text: "OpenAI / Personal · Plus\nWeekly · 74% Used\nSat, Nov 7 12:03 AM", width: 183))
        // Windows native keyboard capture 42362619856: 19-point heading,
        // five-point gap, 35-point detail block and 22 points of padding/border.
        XCTAssertEqual(host.fittingSize, CGSize(width: 183, height: 81))
    }

    @MainActor func testHistoryReadoutFractionalAdvanceKeepsAllLinesAndDescenders() throws {
        for (count, height) in [(1, 64), (2, 81), (4, 116), (12, 254)] {
            let body = Array(repeating: "Hg", count: count).joined(separator: "\n")
            let renderer = ImageRenderer(content: ReferenceHistoryTooltip(text: "Hg\n" + body, width: 183))
            renderer.scale = 1
            let image = NSBitmapImageRep(cgImage: try XCTUnwrap(renderer.cgImage))
            XCTAssertEqual(image.pixelsHigh, height)
            let rows = inkRows(image, minimum: 0.65)
            let starts = rows.filter { !rows.contains($0 - 1) }
            XCTAssertEqual(starts.count, count + 1, "Every detail line and the heading must render")
            XCTAssertGreaterThan(try XCTUnwrap(rows.last), height - 20)
            XCTAssertLessThan(try XCTUnwrap(rows.last), height - 10, "Keep descenders inside the bottom padding")
        }
    }

    @MainActor func testEarnedResetDialogRetainsMeasuredWindowsGeometry() {
        let host = NSHostingView(rootView: DetailsDialog(title: "Available resets", close: {}) {
            VStack(alignment: .leading, spacing: 8) {
                DetailLine(label: "OpenAI / Personal · Plus", value: "2 reported available")
                Text("Snapshot fetched 11/4/2026 10:16 AM · Demo").frame(minHeight: 19)
                Text("• Sun, Nov 8 10:16 AM · available").frame(minHeight: 19)
                Text("• Fri, Nov 13 10:16 AM · available").frame(minHeight: 19)
            }
        })
        // Windows native run 42361188549: exact outer border 333×285.
        XCTAssertEqual(host.fittingSize.width, 333, accuracy: 0.5)
        XCTAssertEqual(host.fittingSize.height, 285, accuracy: 0.5)
    }

    @MainActor func testDialogMeasuresWrappedBodyAtItsFinalWidth() {
        let message = String(repeating: "A long provider message must wrap without clipping the title or footer. ", count: 80)
        let host = NSHostingView(rootView: DetailsDialog(title: "Provider status", close: {}) {
            Text(message).frame(maxWidth: .infinity, alignment: .leading)
        })
        XCTAssertEqual(host.fittingSize.width, 548, accuracy: 0.5)
        // The body reaches the 420-point scroll cap. The title, title gap,
        // padding, separator, 44-point footer action and border still need space.
        XCTAssertEqual(host.fittingSize.height, 605, accuracy: 0.5)
        let capped = NSHostingView(rootView: DetailsDialog(title: "Provider status", maximumHeight: 300, close: {}) {
            Text(message).frame(maxWidth: .infinity, alignment: .leading)
        })
        XCTAssertEqual(capped.fittingSize.height, 300, accuracy: 0.5)
    }

    @MainActor func testNotificationBannerMatchesCurrentNativeWindowsBounds() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = AppStore(database: try LocalStore(url: directory.appendingPathComponent("banner.db")))
        store.enterDemo()
        await store.waitForPendingMutations()
        let account = try XCTUnwrap(store.state.accounts.first)
        let alert = AlertEvent(id: "banner-layout", accountID: account.id, windowID: nil,
                               title: "Scrooge Notification Test",
                               detail: "This is a test. Your account usage has not changed.", createdAt: .now)
        let host = NSHostingView(rootView: AlertBannerView(alert: alert).environment(store))
        // Native run42383175231:440×154 banner plus20-point margins on all sides.
        XCTAssertEqual(host.fittingSize.width, 480, accuracy: 0.5)
        XCTAssertEqual(host.fittingSize.height, 194, accuracy: 0.5)
        for (title, width) in [("Show Info", 125.0), ("Snooze 1 Hour", 153.0), ("Dismiss", 110.0)] {
            let button = NSHostingView(rootView: Button {} label: { DialogActionLabel(title: title) }
                .buttonStyle(ScroogeButtonStyle()))
            XCTAssertEqual(button.fittingSize.width, width, accuracy: 0.5)
            XCTAssertEqual(button.fittingSize.height, 44, accuracy: 0.5)
        }
        // The source caps the banner at520 points before wrapping its labels.
        // Preserve its18-point inset and full44-point actions when either text
        // block grows. The old unconstrained measurement retained194 points
        // for both cases and compressed their content inside the short frame.
        for (title, detail, height) in [
            ("Critical Alert · Quota Refresh",
             "Codex · Weekly · 2h 13m · Sat, Nov 7 1:39 PM CST · Personal account for development and research projects", 210.0),
            ("Codex · Weekly for development and research projects Is Running Low",
             "10% Left · OpenAI / Personal account for development and research projects", 211.0)
        ] {
            var wrapped = alert
            wrapped.title = title
            wrapped.detail = detail
            let content = AlertBannerView(alert: wrapped).environment(store)
            let host = NSHostingView(rootView: content)
            XCTAssertEqual(host.fittingSize.width, 560, accuracy: 0.5)
            XCTAssertEqual(host.fittingSize.height, height, accuracy: 0.5)
            let renderer = ImageRenderer(content: content)
            renderer.scale = 1
            let image = NSBitmapImageRep(cgImage: try XCTUnwrap(renderer.cgImage))
            XCTAssertEqual(image.pixelsWide, 560)
            XCTAssertEqual(image.pixelsHigh, Int(height))
        }
    }

    @MainActor func testActionButtonsMatchCapturedWindowsBounds() {
        for (title, symbol, width) in [("Settings", "gearshape", 113.0), ("Refresh", "arrow.clockwise", 109.0)] {
            let host = NSHostingView(rootView: Button {} label: { ActionLabel(title: title, symbol: symbol) }
                .buttonStyle(ScroogeButtonStyle()))
            XCTAssertEqual(host.fittingSize.width, width, accuracy: 0.5)
            XCTAssertEqual(host.fittingSize.height, 44, accuracy: 0.5)
        }
    }

    @MainActor func testSortIconCanvasExtentsMatchWindows() {
        for (symbol, width, height) in [("battery.100percent", 22.0, 20.0), ("battery.25percent", 22, 20),
            ("circle.grid.3x3.fill", 20, 22), ("gearshape", 20, 20)] {
            let host = NSHostingView(rootView: ActionIcon(symbol: symbol, size: 20))
            XCTAssertEqual(host.fittingSize.width, width, accuracy: 0.5)
            XCTAssertEqual(host.fittingSize.height, height, accuracy: 0.5)
        }
    }

    @MainActor func testButtonOuterMinimaIncludeTheirBorders() {
        let icon = NSHostingView(rootView: Button {} label: { ActionIcon(symbol: "gearshape", size: 20) }
            .buttonStyle(ScroogeButtonStyle(horizontalPadding: 11)))
        XCTAssertEqual(icon.fittingSize.width, 44, accuracy: 0.5)
        XCTAssertEqual(icon.fittingSize.height, 44, accuracy: 0.5)
        for (inside, outer) in [(52.0, 54.0), (68, 70), (78, 80)] {
            let host = NSHostingView(rootView: Button {} label: {
                Text("Action").frame(minHeight: inside)
            }.buttonStyle(ScroogeButtonStyle()))
            XCTAssertEqual(host.fittingSize.height, outer, accuracy: 0.5)
        }
    }

    @MainActor func testCountdownUsesCapturedWindowsLineHeightAndBaseline() throws {
        let image = try render("Hg")
        XCTAssertEqual(image.pixelsHigh, 24)
        let rows = inkRows(image)
        XCTAssertEqual(try XCTUnwrap(rows.first), 4, accuracy: 1)
        XCTAssertLessThan(try XCTUnwrap(rows.last), 24, "Descenders must fit inside the line")
    }

    @MainActor func testWrappedCountdownRetainsEveryLineAtWindowsAdvance() throws {
        let image = try render("Reset Due — Checking")
        XCTAssertEqual(image.pixelsHigh, 48)
        let rows = inkRows(image)
        var starts: [Int] = []
        for row in rows where !rows.contains(row - 1) { starts.append(row) }
        XCTAssertEqual(starts.count, 2, "A smaller layout must not truncate the second rendered line")
        // Different capital glyphs can differ by one raster row in their ink top.
        if starts.count == 2 { XCTAssertEqual(starts[1] - starts[0], 24, accuracy: 1) }
        XCTAssertLessThan(try XCTUnwrap(rows.last), 48)
    }

    @MainActor func testCapturedDashboardLabelLineHeights() throws {
        for (size, height) in [(14.0, 17), (16.0, 20), (20.0, 24), (26.0, 32), (32.0, 39)] {
            let image = try render("Hg", size: size)
            XCTAssertEqual(image.pixelsHigh, height, "Captured Windows line height at \(size) points")
            XCTAssertFalse(inkRows(image).isEmpty)
        }
    }

    @MainActor func testPageAndBannerHeadingMetricsKeepDescenders() throws {
        for (size, height) in [(15.0, 18), (21.0, 26), (24.0, 29)] {
            let image = try render("Hg", size: size)
            XCTAssertEqual(image.pixelsHigh, height)
            let rows = inkRows(image)
            XCTAssertGreaterThan(try XCTUnwrap(rows.first), 0)
            XCTAssertLessThan(try XCTUnwrap(rows.last), height - 1)
        }
    }

    @MainActor private func render(_ text: String, size: CGFloat = 20) throws -> NSBitmapImageRep {
        let renderer = ImageRenderer(content:
            Text(verbatim: text).font(.reference(size: size, weight: .semibold))
                .foregroundStyle(.white).referenceFallbackLineMetrics(size: size)
                .frame(width: 163, alignment: .leading).background(.black))
        renderer.scale = 1
        return NSBitmapImageRep(cgImage: try XCTUnwrap(renderer.cgImage))
    }

    private func inkRows(_ image: NSBitmapImageRep, minimum: CGFloat = 0.8) -> [Int] {
        (0..<image.pixelsHigh).filter { y in
            (0..<image.pixelsWide).contains { x in
                guard let color = image.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else { return false }
                return color.alphaComponent > 0.8 && color.redComponent > minimum && color.greenComponent > minimum && color.blueComponent > minimum
            }
        }
    }
}

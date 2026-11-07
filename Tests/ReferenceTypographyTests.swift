import AppKit
import SwiftUI
import XCTest
@testable import AITokenScrooge

final class ReferenceTypographyTests: XCTestCase {
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

    private func inkRows(_ image: NSBitmapImageRep) -> [Int] {
        (0..<image.pixelsHigh).filter { y in
            (0..<image.pixelsWide).contains { x in
                guard let color = image.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else { return false }
                return color.alphaComponent > 0.8 && color.redComponent > 0.8 && color.greenComponent > 0.8 && color.blueComponent > 0.8
            }
        }
    }
}

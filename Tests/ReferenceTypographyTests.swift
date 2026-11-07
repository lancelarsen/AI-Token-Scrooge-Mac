import AppKit
import SwiftUI
import XCTest
@testable import AITokenScrooge

final class ReferenceTypographyTests: XCTestCase {
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

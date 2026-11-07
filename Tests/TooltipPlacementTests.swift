import CoreGraphics
import XCTest
@testable import AITokenScrooge

final class TooltipPlacementTests: XCTestCase {
    func testNativeWindowsTooltipCapturesRetainZeroGapAndScreenClamping() {
        let screen = CGRect(x: 0, y: 0, width: 1024, height: 768)
        // Native captures 42364265780 and 42365234171, converted from top origin.
        let selector = NativeTooltipPlacement.frame(target: CGRect(x: 168, y: 312, width: 82, height: 66),
                                                    size: CGSize(width: 278, height: 57), screen: screen)
        XCTAssertEqual(selector, CGRect(x: 70, y: 378, width: 278, height: 57))
        let edge = NativeTooltipPlacement.frame(target: CGRect(x: 56, y: 312, width: 82, height: 66),
                                                size: CGSize(width: 278, height: 57), screen: screen)
        XCTAssertEqual(edge, CGRect(x: 0, y: 378, width: 278, height: 57))
        let reset = NativeTooltipPlacement.frame(target: CGRect(x: 479, y: 233, width: 62, height: 74),
                                                 size: CGSize(width: 209, height: 110), screen: screen)
        XCTAssertEqual(reset.minX, 405, accuracy: 0.5) // Windows rounds to physical pixels.
        XCTAssertEqual(reset.minY, 307)
    }

    func testNativeTooltipFlipsBelowTargetAndUsesTranslatedDisplayBounds() {
        let screen = CGRect(x: -1600, y: 200, width: 1400, height: 800)
        let target = CGRect(x: -900, y: 970, width: 80, height: 20)
        let size = CGSize(width: 278, height: 57)
        let frame = NativeTooltipPlacement.frame(target: target, size: size, screen: screen)
        XCTAssertEqual(frame.maxY, target.minY, "When Top cannot fit, place below the complete target")
        XCTAssertEqual(frame.midX, target.midX)
        XCTAssertTrue(screen.contains(frame))
        let right = NativeTooltipPlacement.frame(target: CGRect(x: -220, y: 500, width: 20, height: 20), size: size, screen: screen)
        XCTAssertEqual(right.maxX, screen.maxX)
        XCTAssertTrue(screen.contains(right))
    }
}

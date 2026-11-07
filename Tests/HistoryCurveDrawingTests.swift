import SwiftUI
import XCTest
@testable import AITokenScrooge

final class HistoryCurveDrawingTests: XCTestCase {
    func testResetStepGapAndIsolatedObservationRetainTheirGeometry() throws {
        let points = [point(0, 60), point(10, 40), point(20, 100, replenished: 40),
                      point(30, 20, starts: true, replenished: 100)]
        let drawing = HistoryCurveDrawing(points: ["a": points, "empty": []], top: 90, height: 100,
                                          project: { $0.timeIntervalSince1970 })
        let segments = try XCTUnwrap(drawing.segments["a"])
        XCTAssertEqual(segments.count, 2, "An observation gap must not be bridged")
        XCTAssertEqual(vertices(segments[0].line), [CGPoint(x: 0, y: 150), CGPoint(x: 10, y: 130),
                                                   CGPoint(x: 20, y: 130), CGPoint(x: 20, y: 190)])
        XCTAssertEqual(vertices(segments[0].fill), [CGPoint(x: 0, y: 190), CGPoint(x: 0, y: 150),
                                                   CGPoint(x: 10, y: 130), CGPoint(x: 20, y: 130),
                                                   CGPoint(x: 20, y: 190), CGPoint(x: 20, y: 190)])
        var closed = false
        segments[0].fill.forEach { if case .closeSubpath = $0 { closed = true } }
        XCTAssertTrue(closed, "Area fill must close to the baseline")
        XCTAssertNil(segments[0].singlePoint)
        XCTAssertEqual(vertices(segments[1].line), [CGPoint(x: 30, y: 110)])
        XCTAssertEqual(segments[1].singlePoint?.boundingRect, CGRect(x: 27.5, y: 107.5, width: 5, height: 5))
        XCTAssertTrue(try XCTUnwrap(drawing.segments["empty"]).isEmpty)
    }

    func testReplacementProjectionAndHeightProduceFreshPixelGeometry() throws {
        let points = ["a": [point(10, 50)]]
        let first = HistoryCurveDrawing(points: points, top: 90, height: 100,
                                        project: { $0.timeIntervalSince1970 })
        XCTAssertTrue(first.matches(top: 90, height: 100))
        XCTAssertFalse(first.matches(top: 90, height: 200))
        XCTAssertFalse(first.matches(top: 80, height: 100))
        XCTAssertFalse(HistoryCurveDrawing().matches(top: 90, height: 100))
        let resized = HistoryCurveDrawing(points: points, top: 80, height: 200,
                                          project: { $0.timeIntervalSince1970 * 2 })
        XCTAssertEqual(vertices(try XCTUnwrap(resized.segments["a"]?.first).line), [CGPoint(x: 20, y: 180)])
        let refreshed = HistoryCurveDrawing(points: ["a": [point(10, 0)]], top: 80, height: 200,
                                            project: { $0.timeIntervalSince1970 * 2 })
        XCTAssertEqual(vertices(try XCTUnwrap(refreshed.segments["a"]?.first).line), [CGPoint(x: 20, y: 80)])
    }

    private func point(_ seconds: Double, _ remaining: Decimal, starts: Bool = false, replenished: Decimal? = nil) -> HistoryPoint {
        HistoryPoint(at: Date(timeIntervalSince1970: seconds), remaining: remaining, windowID: "weekly",
                     startsSegment: starts, estimated: false, replenishedFrom: replenished)
    }
    private func vertices(_ path: Path) -> [CGPoint] {
        var result: [CGPoint] = []
        path.forEach {
            switch $0 {
            case .move(to: let point), .line(to: let point): result.append(point)
            default: break
            }
        }
        return result
    }
}

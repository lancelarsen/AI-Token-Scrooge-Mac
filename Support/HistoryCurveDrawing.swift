import SwiftUI

/// Prepared with the history projection or plot height, never with scroll offset.
struct HistoryCurveDrawing {
    struct Segment {
        let line: Path
        let fill: Path
        let singlePoint: Path?
    }
    private struct Bounds: Equatable {
        let top: Double
        let height: Double
    }
    private var bounds: Bounds?
    private(set) var segments: [String: [Segment]] = [:]
    init() {}
    init(points: [String: [HistoryPoint]], top: Double, height: Double, project: (Date) -> Double) {
        bounds = Bounds(top: top, height: height)
        for (accountID, points) in points {
            var prepared: [Segment] = []
            var segment: [CGPoint] = []
            func flush() {
                guard let first = segment.first, let last = segment.last else { return }
                var line = Path(); line.addLines(segment)
                var fill = Path(); fill.move(to: CGPoint(x: first.x, y: top + height))
                for point in segment { fill.addLine(to: point) }
                fill.addLine(to: CGPoint(x: last.x, y: top + height)); fill.closeSubpath()
                let dot = segment.count == 1 ? Path(ellipseIn: CGRect(x: first.x - 2.5, y: first.y - 2.5, width: 5, height: 5)) : nil
                prepared.append(Segment(line: line, fill: fill, singlePoint: dot))
                segment.removeAll(keepingCapacity: true)
            }
            for point in points {
                if point.startsSegment { flush() }
                let x = project(point.at)
                if let before = point.replenishedFrom, !segment.isEmpty {
                    segment.append(CGPoint(x: x, y: top + NSDecimalNumber(decimal: before).doubleValue / 100 * height))
                }
                segment.append(CGPoint(x: x, y: top + NSDecimalNumber(decimal: point.remaining).doubleValue / 100 * height))
            }
            flush()
            segments[accountID] = prepared
        }
    }
    func matches(top: Double, height: Double) -> Bool { bounds == Bounds(top: top, height: height) }
}

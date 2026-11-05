import Foundation

/// Windows AccountDragLayout: neighboring centers control the placeholder slot.
struct AccountDragLayout {
    let heights: [Double]
    let sourceIndex: Int
    let spacing: Double
    let originalTops: [Double]
    private let remaining: [Int]
    private(set) var slot: Int
    private(set) var tops: [Double]

    init?(heights: [Double], sourceIndex: Int, spacing: Double) {
        guard heights.indices.contains(sourceIndex),
              heights.allSatisfy({ $0.isFinite && $0 > 0 }),
              spacing.isFinite, spacing >= 0 else { return nil }
        self.heights = heights
        self.sourceIndex = sourceIndex
        self.spacing = spacing
        self.remaining = heights.indices.filter { $0 != sourceIndex }
        self.slot = sourceIndex
        var top = 0.0
        let initial = heights.map { height in
            defer { top += height + spacing }
            return top
        }
        self.tops = initial
        self.originalTops = initial
    }

    @discardableResult mutating func move(centerY: Double) -> Bool {
        guard centerY.isFinite else { return false }
        let previous = slot
        while slot > 0 && centerY < tops[remaining[slot - 1]] + heights[remaining[slot - 1]] / 2 {
            slot -= 1
            rebuild()
        }
        while slot < remaining.count && centerY > tops[remaining[slot]] + heights[remaining[slot]] / 2 {
            slot += 1
            rebuild()
        }
        return previous != slot
    }

    private mutating func rebuild() {
        var order = remaining
        order.insert(sourceIndex, at: slot)
        var top = 0.0
        for index in order {
            tops[index] = top
            top += heights[index] + spacing
        }
    }

    /// Per-tick delta matching Windows' 56-point edge zone and 10-point maximum.
    static func scrollStep(pointerY: Double, top: Double, bottom: Double) -> Double {
        guard pointerY.isFinite, top.isFinite, bottom.isFinite,
              pointerY >= top, pointerY <= bottom else { return 0 }
        let edge = min(56, (bottom - top) / 3)
        guard edge > 0 else { return 0 }
        if pointerY < top + edge { return -10 * (1 - (pointerY - top) / edge) }
        if pointerY > bottom - edge { return 10 * (1 - (bottom - pointerY) / edge) }
        return 0
    }
}

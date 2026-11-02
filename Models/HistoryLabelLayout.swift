import Foundation

enum HistoryLabelLayout {
    /// Input order is vertical order. Preserve it while fitting labels into the graph.
    static func positions(_ desired: [Double], top: Double, bottom: Double, spacing: Double = 25) -> [Double] {
        guard !desired.isEmpty else { return [] }
        let bottom = max(top, bottom)
        let spacing = min(spacing, (bottom - top) / Double(max(1, desired.count - 1)))
        var positions: [Double] = []
        for value in desired {
            positions.append(max(min(bottom, max(top, value)), positions.last.map { $0 + spacing } ?? top))
        }
        positions[positions.count - 1] = min(positions.last!, bottom)
        if positions.count > 1 {
            for index in stride(from: positions.count - 2, through: 0, by: -1) { positions[index] = min(positions[index], positions[index + 1] - spacing) }
        }
        return positions
    }
}

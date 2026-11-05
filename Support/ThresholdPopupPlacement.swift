import CoreGraphics

/// Windows keeps the first popup top fixed until dismissal, even as its width changes.
struct ThresholdPopupPlacement {
    private var topOffset: CGFloat?

    mutating func reset() { topOffset = nil }

    mutating func frame(anchor: CGPoint, size: CGSize, contentBounds: CGRect) -> CGRect {
        if topOffset == nil {
            topOffset = max(0, contentBounds.maxY - anchor.y - size.height - 2)
        }
        let left = contentBounds.minX + 4
        let right = max(left, contentBounds.maxX - size.width - 4)
        let x = min(max(left, anchor.x - size.width / 2), right)
        let y = contentBounds.maxY - (topOffset ?? 0) - size.height
        return CGRect(origin: CGPoint(x: x, y: y), size: size)
    }
}

import CoreGraphics

/// Native Windows ToolTip placement: Top of its target, screen-constrained,
/// with no history-readout gap. Input coordinates use the AppKit bottom origin.
enum NativeTooltipPlacement {
    static func frame(target: CGRect, size: CGSize, screen: CGRect) -> CGRect {
        let x = min(max(screen.minX, target.midX - size.width / 2), screen.maxX - size.width)
        let preferredY = target.maxY + size.height <= screen.maxY ? target.maxY : target.minY - size.height
        let y = min(max(screen.minY, preferredY), screen.maxY - size.height)
        return CGRect(origin: CGPoint(x: x, y: y), size: size)
    }
}

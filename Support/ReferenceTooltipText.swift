import SwiftUI

/// Classic Segoe UI 13-point text shared by Windows help, reset context and
/// history details. Keep fractional baselines and round the complete block.
struct ReferenceTooltipText: View {
    let text: String
    var body: some View {
        let font = ReferenceTypography.measuringFont(ofSize: 13)
        let advance = font.ascender - font.descender + font.leading
        TooltipLineBox(advance: advance) {
            Text(text).font(.reference(size: 13))
                .textRenderer(TooltipTextRenderer(baseline: font.ascender, advance: advance))
        }
    }
}

private struct TooltipLineBox: Layout {
    let advance: CGFloat
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let text = subviews.first else { return .zero }
        let natural = text.sizeThatFits(.init(width: proposal.width, height: nil))
        let lines = max(1, (natural.height / advance.rounded()).rounded())
        return CGSize(width: natural.width, height: ceil(lines * advance))
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, proposal: .init(width: bounds.width, height: nil))
    }
}

private struct TooltipTextRenderer: TextRenderer {
    let baseline: CGFloat
    let advance: CGFloat
    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let top = layout.first?.typographicBounds.rect.minY ?? 0
        for (index, line) in layout.enumerated() {
            var lineContext = context
            lineContext.translateBy(x: 0, y: baseline + CGFloat(index) * advance - (line.origin.y - top))
            lineContext.draw(line)
        }
    }
}

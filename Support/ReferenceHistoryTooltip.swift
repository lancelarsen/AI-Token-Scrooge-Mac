import SwiftUI

/// Windows HistoryChartInput uses classic Segoe UI and its fractional line
/// advance. SwiftUI otherwise rounds each 13-point line down to 17 points.
struct ReferenceHistoryTooltip: View {
    let text: String
    let width: CGFloat

    var body: some View {
        let lines = text.split(separator: "\n", maxSplits: 1).map(String.init)
        VStack(alignment: .leading, spacing: 5) {
            Text(lines.first ?? "").font(.reference(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: "#F2F1F5"))
            if lines.count > 1 {
                let font = ReferenceTypography.measuringFont(ofSize: 13)
                let advance = font.ascender - font.descender + font.leading
                HistoryDetailLineBox(advance: advance) {
                    Text(lines[1]).font(.reference(size: 13)).foregroundStyle(Theme.dialogText)
                        .textRenderer(HistoryDetailRenderer(baseline: font.ascender, advance: advance))
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10).padding(1)
        .frame(width: width, alignment: .leading).fixedSize(horizontal: false, vertical: true)
        .background(Color(hex: "#222329"), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(hex: "#65577F"), lineWidth: 1))
    }
}

private struct HistoryDetailLineBox: Layout {
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

private struct HistoryDetailRenderer: TextRenderer {
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

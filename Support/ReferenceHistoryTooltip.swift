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
                ReferenceTooltipText(text: lines[1]).foregroundStyle(Theme.dialogText)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10).padding(1)
        .frame(width: width, alignment: .leading).fixedSize(horizontal: false, vertical: true)
        .background(Color(hex: "#222329"), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(hex: "#65577F"), lineWidth: 1))
    }
}

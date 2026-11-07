import SwiftUI

/// Classic Segoe UI 13-point text shared by Windows help, reset context and
/// history details. Keep fractional baselines and round the complete block.
struct ReferenceTooltipText: View {
    let text: String
    var body: some View {
        Text(text).font(.reference(size: 13)).referenceClassicLineMetrics(size: 13)
    }
}

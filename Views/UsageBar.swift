import SwiftUI

struct UsageBar: View {
    let window: QuotaWindow
    let thresholds: AlertThresholds
    let changed: (AlertThresholds) -> Void
    let details: () -> Void
    @State private var editing: AlertThresholds?
    var body: some View {
        GeometryReader { geometry in
            let current = editing ?? thresholds
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 11).fill(Color(hex: "#30323C"))
                RoundedRectangle(cornerRadius: 11).fill(LinearGradient(colors: Theme.colors(window.capacity(current)), startPoint: .leading, endPoint: .trailing))
                    .frame(width: geometry.size.width * window.fill)
                Button(action: details) {
                    HStack { Text("\(Format.percent(window.usedPercent)) Used"); Spacer(); Text("\(Format.percent(window.remainingPercent)) Left") }
                        .font(.system(size: 14, weight: .semibold)).padding(.horizontal, 14).frame(height: 48).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityLabel("\(window.name), \(Format.percent(window.remainingPercent)) Remaining. Open Details")
                ForEach(ReminderSeverity.allCases, id: \.self) { level in
                    let value = value(level, current)
                    Capsule().fill(color(level)).frame(width: 5, height: 30)
                        .frame(width: 18, height: 44).contentShape(Rectangle())
                        .position(x: (1 - NSDecimalNumber(decimal: value).doubleValue / 100) * geometry.size.width, y: 24)
                        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("usageBar")).onChanged { drag in
                            var next = editing ?? thresholds
                            next.move(level, to: Decimal(min(100, max(0, (1 - drag.location.x / geometry.size.width) * 100))))
                            editing = next
                        }.onEnded { _ in if let editing { changed(editing) }; editing = nil })
                        .help("\(level.rawValue) @ \(Format.percent(value)) Left")
                        .accessibilityLabel("\(level.rawValue) Alert Threshold")
                        .accessibilityValue(Format.percent(value))
                        .accessibilityAdjustableAction { direction in
                            var next = thresholds; next.move(level, to: value + (direction == .increment ? 1 : -1)); changed(next)
                        }
                }
            }.coordinateSpace(name: "usageBar").overlay(RoundedRectangle(cornerRadius: 11).stroke(Color(hex: "#45464D")))
        }.frame(height: 48)
    }
    private func value(_ severity: ReminderSeverity, _ thresholds: AlertThresholds) -> Decimal {
        switch severity { case .info: thresholds.info; case .warning: thresholds.warning; case .critical: thresholds.critical }
    }
    private func color(_ severity: ReminderSeverity) -> Color { switch severity { case .info: Color(hex: "#58A6FF"); case .warning: Color(hex: "#F2C94C"); case .critical: Color(hex: "#F05B69") } }
}

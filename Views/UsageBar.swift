import SwiftUI

struct UsageBar: View {
    let window: QuotaWindow
    var alertsEnabled = true
    let thresholds: AlertThresholds
    let changed: (AlertThresholds) -> Void
    let details: () -> Void
    @State private var editing: AlertThresholds?
    @State private var editingSeverity: ReminderSeverity?
    @State private var dragStartPosition: Double?
    @State private var hoveredSeverity: ReminderSeverity?
    private var readoutSeverity: ReminderSeverity? { alertsEnabled ? editingSeverity ?? hoveredSeverity ?? focusedThreshold : nil }
    @FocusState private var focusedThreshold: ReminderSeverity?
    var body: some View {
        GeometryReader { geometry in
            let current = editing ?? thresholds
            let markerSpan = max(0, geometry.size.width - 16)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 11).fill(Color(hex: "#30333E"))
                RoundedRectangle(cornerRadius: 11).fill(LinearGradient(colors: Theme.colors(window.capacity(current)), startPoint: .leading, endPoint: .trailing))
                    .frame(width: geometry.size.width * window.fill)
                Button(action: details) {
                    Color.clear.frame(height: 48).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityLabel("\(window.name), \(Format.percent(window.remainingPercent)) Remaining. Open Details")
                ForEach(alertsEnabled ? ReminderSeverity.allCases : [], id: \.self) { level in
                    let value = value(level, current)
                    Capsule().fill(color(level))
                        .overlay(Capsule().strokeBorder(Color(hex: "#30333E"), lineWidth: 3))
                        .frame(width: 10, height: 36)
                        // Match the Windows Thumb target; the painted marker stays 10 by 36.
                        .frame(width: 32, height: 48).contentShape(Rectangle())
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(focusedThreshold == level ? Theme.accent : .clear, lineWidth: 2))
                        .focusable()
                        .focused($focusedThreshold, equals: level)
                        .focusEffectDisabled()
                        .onKeyPress(keys: [.leftArrow, .rightArrow, .upArrow, .downArrow]) { press in
                            let increase = press.key == .leftArrow || press.key == .upArrow
                            var next = thresholds
                            next.move(level, to: value + (increase ? 1 : -1))
                            changed(next)
                            return .handled
                        }
                        .onKeyPress(.escape) {
                            editing = nil; editingSeverity = nil; dragStartPosition = nil; hoveredSeverity = nil; focusedThreshold = nil
                            return .handled
                        }
                        .position(x: 8 + (1 - NSDecimalNumber(decimal: value).doubleValue / 100) * markerSpan, y: 24)
                        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("usageBar")).onChanged { drag in
                            guard markerSpan > 0 else { return }
                            if dragStartPosition == nil {
                                dragStartPosition = (1 - NSDecimalNumber(decimal: self.value(level, thresholds)).doubleValue / 100) * markerSpan
                            }
                            var next = editing ?? thresholds
                            let position = (dragStartPosition ?? 0) + drag.translation.width
                            next.move(level, to: Decimal(min(100, max(0, (1 - position / markerSpan) * 100))))
                            editingSeverity = level
                            editing = next
                        }.onEnded { _ in
                            if let editing, editing != thresholds { changed(editing) }
                            editing = nil; editingSeverity = nil; dragStartPosition = nil
                        })
                        .onHover { hoveredSeverity = $0 ? level : (hoveredSeverity == level ? nil : hoveredSeverity) }
                        .accessibilityLabel("\(level.rawValue) Alert Threshold")
                        .accessibilityValue(Format.percent(value))
                        .accessibilityHint("Drag Horizontally or Use Arrow Keys to Adjust")
                        .accessibilityAdjustableAction { direction in
                            var next = thresholds; next.move(level, to: value + (direction == .increment ? 1 : -1)); changed(next)
                        }
                }
                // Keep labels above the draggable markers without intercepting input.
                HStack {
                    Text(window.usedPercent.map { "\(Format.percent($0)) used" } ?? "Usage unavailable").fontWeight(.semibold)
                    Spacer()
                    Text(window.remainingPercent.map { "\(Format.percent($0)) left" } ?? "Left unavailable")
                }
                .font(.system(size: 16)).padding(.horizontal, 15)
                .allowsHitTesting(false).accessibilityHidden(true)
            }.coordinateSpace(name: "usageBar").overlay(RoundedRectangle(cornerRadius: 11).stroke(Color(hex: "#515461")))
                .background {
                    if let level = readoutSeverity {
                        HistoryPointerTracking(severity: level,
                            text: "\(level.rawValue) Alert @ \(Format.percent(value(level, current))) Left",
                            pinned: true,
                            anchor: CGPoint(x: 8 + (1 - NSDecimalNumber(decimal: value(level, current)).doubleValue / 100) * markerSpan, y: 0),
                            onMove: { _ in })
                    }
                }
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { _ in
                    if editing == nil { hoveredSeverity = nil; focusedThreshold = nil }
                }
                .onChange(of: alertsEnabled) { _, enabled in
                    if !enabled { editing = nil; editingSeverity = nil; dragStartPosition = nil; hoveredSeverity = nil; focusedThreshold = nil }
                }
        }.frame(height: 48)
    }
    private func value(_ severity: ReminderSeverity, _ thresholds: AlertThresholds) -> Decimal {
        switch severity { case .info: thresholds.info; case .warning: thresholds.warning; case .critical: thresholds.critical }
    }
    private func color(_ severity: ReminderSeverity) -> Color { switch severity { case .info: Color(hex: "#58A6FF"); case .warning: Color(hex: "#F2C94C"); case .critical: Color(hex: "#FF5D68") } }
}

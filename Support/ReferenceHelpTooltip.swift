import SwiftUI

/// Plain WinUI help is capped at 320 points; history readouts have their own
/// wider layout. Keeping this surface separate also permits direct rendering
/// of the same content used by the floating native panel.
struct ReferenceHelpTooltip: View {
    let text: String
    let width: CGFloat

    static func width(for text: String, availableWidth: CGFloat) -> CGFloat {
        let longest = text.components(separatedBy: "\n").map {
            ($0 as NSString).size(withAttributes: [.font: ReferenceTypography.measuringFont(ofSize: 13)]).width
        }.max() ?? 0
        return max(0, min(320, availableWidth, ceil(longest + 30)))
    }

    var body: some View {
        ReferenceTooltipText(text: text)
            .foregroundStyle(Color(red: 242 / 255, green: 241 / 255, blue: 245 / 255))
            .padding(.horizontal, 14).padding(.vertical, 10).padding(1)
            .frame(width: width, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .background(Color(red: 34 / 255, green: 35 / 255, blue: 41 / 255), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(red: 101 / 255, green: 87 / 255, blue: 127 / 255), lineWidth: 1))
    }
}

/// Shared with quota rows, matching Windows ResetCountdown.
struct ResetCountdownText: View {
    let date: Date?
    let now: Date
    let zone: TimeZone
    var isExpiry = false
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(Format.countdown(date, now: now))
                .font(.reference(size: 20, weight: .semibold))
                .foregroundStyle(Color(hex: isExpiry ? "#EAAA51" : "#BDA3F5"))
                .referenceFallbackLineMetrics(size: 20)
            Text(Format.date(date, zone: zone))
                .font(.reference(size: 12)).foregroundStyle(Theme.dialogText)
        }
    }
}

struct ResetTooltipContent: Equatable {
    let context: String
    let date: Date
    let now: Date
    let zone: TimeZone
    var isExpiry = false

    func width(available: CGFloat) -> CGFloat {
        let contextWidth = context.components(separatedBy: "\n").map {
            ($0 as NSString).size(withAttributes: [.font: ReferenceTypography.measuringFont(ofSize: 13)]).width
        }.max() ?? 0
        let countdownWidth = (Format.countdown(date, now: now) as NSString).size(withAttributes: [.font: ReferenceTypography.measuringFont(ofSize: 20, weight: .semibold)]).width
        let dateWidth = (Format.date(date, zone: zone) as NSString).size(withAttributes: [.font: ReferenceTypography.measuringFont(ofSize: 12)]).width
        return max(0, min(320, available, ceil(max(contextWidth, max(countdownWidth, dateWidth) + 37) + 30)))
    }
}

struct ReferenceResetTooltip: View {
    let content: ResetTooltipContent
    let width: CGFloat
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ReferenceTooltipText(text: content.context).foregroundStyle(Color(hex: "#F2F1F5"))
            HStack(alignment: .top, spacing: 12) {
                ResetCountdownIcon(isExpiry: content.isExpiry)
                    .environment(\.actionForeground, Color(hex: content.isExpiry ? "#EAAA51" : "#BDA3F5"))
                    .padding(.top, 3)
                ResetCountdownText(date: content.date, now: content.now, zone: content.zone, isExpiry: content.isExpiry)
            }.padding(.top, 7)
        }
        .padding(.horizontal, 14).padding(.vertical, 10).padding(1)
        .frame(width: width, alignment: .leading).fixedSize(horizontal: false, vertical: true)
        .background(Color(hex: "#222329"), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(hex: "#65577F"), lineWidth: 1))
    }
}

/// Keep the 25-point slot while matching the visible Fluent glyph bounds.
struct ResetCountdownIcon: View {
    var isExpiry = false
    var body: some View {
        ActionIcon(symbol: isExpiry ? "clock" : "arrow.clockwise", size: 25)
            .scaleEffect(isExpiry ? 44.0 / 41.0 : 1)
            .offset(x: isExpiry ? 1 : 0)
    }
}

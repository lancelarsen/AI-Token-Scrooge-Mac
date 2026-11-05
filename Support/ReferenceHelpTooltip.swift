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
        Text(text).font(.reference(size: 13))
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
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(Format.countdown(date, now: now))
                .font(.reference(size: 20, weight: .semibold))
                .foregroundStyle(Color(hex: "#BDA3F5"))
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

    func width(available: CGFloat) -> CGFloat {
        let contextWidth = context.components(separatedBy: "\n").map {
            ($0 as NSString).size(withAttributes: [.font: ReferenceTypography.measuringFont(ofSize: 13)]).width
        }.max() ?? 0
        let countdownWidth = (Format.countdown(date, now: now) as NSString).size(withAttributes: [.font: ReferenceTypography.measuringFont(ofSize: 20, weight: .semibold)]).width
        let dateWidth = (Format.date(date, zone: zone) as NSString).size(withAttributes: [.font: ReferenceTypography.measuringFont(ofSize: 12)]).width
        return max(0, min(320, available, ceil(max(contextWidth, countdownWidth, dateWidth) + 30)))
    }
}

struct ReferenceResetTooltip: View {
    let content: ResetTooltipContent
    let width: CGFloat
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(content.context).font(.reference(size: 13)).foregroundStyle(Color(hex: "#F2F1F5"))
            ResetCountdownText(date: content.date, now: content.now, zone: content.zone)
        }
        .padding(.horizontal, 14).padding(.vertical, 10).padding(1)
        .frame(width: width, alignment: .leading).fixedSize(horizontal: false, vertical: true)
        .background(Color(hex: "#222329"), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(hex: "#65577F"), lineWidth: 1))
    }
}

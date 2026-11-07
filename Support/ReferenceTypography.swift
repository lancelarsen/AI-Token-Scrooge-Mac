import AppKit
import CoreText
import SwiftUI

/// Use the reference face for both rendering and tooltip measurements.
enum ReferenceTypography {
    // Classic faces match the 5.71 installed fonts from the pinned Windows
    // reference runner; see script/windows-ui-reference/README.md for hashes.
    private static let registered: Bool = {
        var loaded = true
        for resource in ["SegoeUI", "SegoeUI-Semibold"] {
            guard let url = Bundle.main.url(forResource: resource, withExtension: "ttf") else { loaded = false; continue }
            loaded = CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil) && loaded
        }
        return loaded
    }()

    private static let nativeTextRegistered: Bool = {
        var loaded = true
        for name in ["SegoeUIVariable-Text", "SegoeUIVariable-Text-Semibold"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { loaded = false; continue }
            loaded = CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil) && loaded
        }
        return loaded
    }()

    /// WinUI TextBlock's default Text face differs metrically from classic Segoe UI.
    static func nativeTextFont(size: CGFloat = 14, semibold: Bool = false) -> Font {
        _ = nativeTextRegistered
        let name = semibold ? "SegoeUIVariableStatic-2580000-a8000" : "SegoeUIVariableStatic-1900000-a8000"
        guard NSFont(name: name, size: size) != nil else { return font(size: size, weight: semibold ? .semibold : .regular) }
        return .custom(name, fixedSize: size)
    }

    private static let iconsRegistered: Bool = {
        guard let url = Bundle.main.url(forResource: "SegoeFluentIcons", withExtension: "ttf") else { return false }
        return CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }()

    private static let symbolsRegistered: Bool = {
        guard let url = Bundle.main.url(forResource: "SegoeUISymbol", withExtension: "ttf") else { return false }
        return CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }()

    static func symbolFont(size: CGFloat) -> Font {
        _ = symbolsRegistered
        return .custom("SegoeUISymbol", fixedSize: size)
    }

    static func iconFont(size: CGFloat) -> Font {
        _ = iconsRegistered
        return .custom("SegoeFluentIcons", fixedSize: size)
    }

    static func measuringFont(ofSize size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
        _ = registered
        if weight == .semibold, let font = NSFont(name: "SegoeUI-Semibold", size: size) { return font }
        guard let font = NSFont(name: "SegoeUI", size: size) else {
            return .systemFont(ofSize: size, weight: weight)
        }
        // Preserve a fallback if a packaged font is unavailable.
        return weight >= .semibold ? NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask) : font
    }

    static func font(size: CGFloat, weight: Font.Weight) -> Font {
        _ = registered
        if weight == .semibold, NSFont(name: "SegoeUI-Semibold", size: size) != nil {
            return .custom("SegoeUI-Semibold", fixedSize: size)
        }
        guard NSFont(name: "SegoeUI", size: size) != nil else { return .system(size: size, weight: weight) }
        return .custom("SegoeUI", fixedSize: size).weight(weight)
    }
}

extension Font {
    static func reference(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        ReferenceTypography.font(size: size, weight: weight)
    }
}

/// The WinUI fallback family uses a .9 em baseline and 1.2 em line advance.
/// These match the captured countdown: 20-point text in a 24-point line.
/// Keep SwiftUI's full shaping/layout, then reposition each rendered line.
private struct ReferenceFallbackTextRenderer: TextRenderer {
    let size: CGFloat
    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let top = layout.first?.typographicBounds.rect.minY ?? 0
        for (index, line) in layout.enumerated() {
            let baseline = size * 0.9 + CGFloat(index) * size * 1.2
            var lineContext = context
            lineContext.translateBy(x: 0, y: baseline - (line.origin.y - top))
            lineContext.draw(line)
        }
    }
}

/// The text child retains its unconstrained natural height. Shrinking its own
/// proposal would truncate wrapped lines before the renderer could draw them.
private struct ReferenceFallbackLineBox: Layout {
    let size: CGFloat
    let naturalLineHeight: CGFloat
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let text = subviews.first else { return .zero }
        let natural = text.sizeThatFits(.init(width: proposal.width, height: nil))
        let lines = max(1, (natural.height / naturalLineHeight).rounded())
        return CGSize(width: natural.width, height: ceil(lines * size * 1.2))
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, proposal: .init(width: bounds.width, height: nil))
    }
}

extension View {
    /// Use only for labels whose native Windows fallback metrics were measured;
    /// regular Segoe and native dialog text retain their own line metrics.
    func referenceFallbackLineMetrics(size: CGFloat, weight: NSFont.Weight = .semibold) -> some View {
        let font = ReferenceTypography.measuringFont(ofSize: size, weight: weight)
        let naturalLineHeight = ceil(font.ascender - font.descender + font.leading)
        return ReferenceFallbackLineBox(size: size, naturalLineHeight: naturalLineHeight) {
            self.textRenderer(ReferenceFallbackTextRenderer(size: size))
        }
    }
}


/// Classic Segoe Label/TextBlock rounds the complete line block upward in
/// WinUI; SwiftUI otherwise rounds each individual line to the nearest point.
private struct ReferenceClassicTextRenderer: TextRenderer {
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

private struct ReferenceClassicLineBox: Layout {
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

extension View {
    /// Apply to a Text with the matching classic font. Native Variable text and
    /// the measured Semibold fallback keep their separate line-box policies.
    func referenceClassicLineMetrics(size: CGFloat) -> some View {
        let font = ReferenceTypography.measuringFont(ofSize: size)
        let advance = font.ascender - font.descender + font.leading
        return ReferenceClassicLineBox(advance: advance) {
            self.textRenderer(ReferenceClassicTextRenderer(baseline: font.ascender, advance: advance))
        }
    }
}

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

    // The pinned Windows runner uses Segoe UI Variable2.03. Keep its full
    // positioning/variation tables instead of flattening them into older faces.
    // CGFont/CTFont are immutable; NSCache serializes its own mutations.
    // A cache miss may create equivalent immutable faces concurrently.
    private final class NativeTextFontCache: @unchecked Sendable {
        private let graphicsFont: CGFont? = {
            guard let url = Bundle.main.url(forResource: "SegoeUIVariable", withExtension: "ttf"),
                  let provider = CGDataProvider(url: url as CFURL) else { return nil }
            return CGFont(provider)
        }()
        private let fonts: NSCache<NSString, CTFont> = {
            let cache = NSCache<NSString, CTFont>()
            cache.countLimit = 32
            return cache
        }()

        func font(size: CGFloat, semibold: Bool) -> CTFont? {
            let key = "\(size)-\(semibold)" as NSString
            if let cached = fonts.object(forKey: key) { return cached }
            guard let graphicsFont else { return nil }
            // XAML optical sizing follows the requested size in typographic
            // points (DIPs *72/96), rather than fixing every label at Text10.5.
            let axes: [NSNumber: Double] = [0x77676874: semibold ? 600 : 400, // wght
                                           0x6F70737A: Double(size) * 0.75] // opsz
            let descriptor = CTFontDescriptorCreateWithAttributes([kCTFontVariationAttribute: axes] as CFDictionary)
            let font = CTFontCreateWithGraphicsFont(graphicsFont, size, nil, descriptor)
            fonts.setObject(font, forKey: key)
            return font
        }
    }
    private static let nativeTextFonts = NativeTextFontCache()

    /// WinUI TextBlock's default Text face differs metrically from classic Segoe UI.
    static func nativeTextFont(size: CGFloat = 14, semibold: Bool = false) -> Font {
        guard let native = nativeTextFonts.font(size: size, semibold: semibold) else {
            return font(size: size, weight: semibold ? .semibold : .regular)
        }
        return Font(native)
    }

    /// AppKit menus share the same immutable font face and axes as SwiftUI text.
    static func nativeMenuFont(size: CGFloat = 14) -> NSFont {
        guard let native = nativeTextFonts.font(size: size, semibold: false) else {
            return measuringFont(ofSize: size)
        }
        return native as NSFont
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


/// Measured Segoe text blocks round the complete fractional line block upward
/// in WinUI; SwiftUI otherwise rounds each individual line to the nearest point.
private struct ReferenceFractionalTextRenderer: TextRenderer {
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

private struct ReferenceFractionalLineBox: Layout {
    let advance: CGFloat
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let text = subviews.first else { return .zero }
        let natural = text.dimensions(in: .init(width: proposal.width, height: nil))
        // SwiftUI's rounded line box is not always advance.rounded(): the
        //22-point face uses30 points, while the16-point face uses21. Recover
        // its actual line box from the first/last baselines before rescaling.
        let lineHeight = natural.height - (natural[.lastTextBaseline] - natural[.firstTextBaseline])
        let lines = max(1, (natural.height / max(1, lineHeight)).rounded())
        return CGSize(width: natural.width, height: ceil(lines * advance))
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, proposal: .init(width: bounds.width, height: nil))
    }
}

extension View {
    /// Measured native Variable labels also round the complete fractional
    /// line block upward. At16 points this is22, rather than SwiftUI's21.
    func referenceNativeTextLineMetrics(size: CGFloat) -> some View {
        let font = ReferenceTypography.nativeMenuFont(size: size)
        let advance = font.ascender - font.descender + font.leading
        return ReferenceFractionalLineBox(advance: advance) {
            self.textRenderer(ReferenceFractionalTextRenderer(baseline: font.ascender, advance: advance))
        }
    }

    /// Apply to a Text with the matching classic font. Native Variable text and
    /// the measured Semibold fallback keep their separate line-box policies.
    func referenceClassicLineMetrics(size: CGFloat) -> some View {
        let font = ReferenceTypography.measuringFont(ofSize: size)
        let advance = font.ascender - font.descender + font.leading
        return ReferenceFractionalLineBox(advance: advance) {
            self.textRenderer(ReferenceFractionalTextRenderer(baseline: font.ascender, advance: advance))
        }
    }
}

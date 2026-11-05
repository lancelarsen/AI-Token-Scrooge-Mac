import AppKit
import CoreText
import SwiftUI

/// Use the reference face for both rendering and tooltip measurements.
enum ReferenceTypography {
    private static let registered: Bool = {
        var loaded = true
        for resource in ["SegoeUI", "SegoeUI-Semibold"] {
            guard let url = Bundle.main.url(forResource: resource, withExtension: "ttf") else { loaded = false; continue }
            loaded = CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil) && loaded
        }
        return loaded
    }()

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
        if weight == .semibold, let font = NSFont(name: "SegoeUI-SemiBold", size: size) { return font }
        guard let font = NSFont(name: "SegoeUI", size: size) else {
            return .systemFont(ofSize: size, weight: weight)
        }
        // Preserve a fallback if a packaged font is unavailable.
        return weight >= .semibold ? NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask) : font
    }

    static func font(size: CGFloat, weight: Font.Weight) -> Font {
        _ = registered
        if weight == .semibold, NSFont(name: "SegoeUI-SemiBold", size: size) != nil {
            return .custom("SegoeUI-SemiBold", fixedSize: size)
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

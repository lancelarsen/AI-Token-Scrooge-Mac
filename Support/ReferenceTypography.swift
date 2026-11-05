import AppKit
import CoreText
import SwiftUI

/// Use the reference face for both rendering and tooltip measurements.
enum ReferenceTypography {
    private static let registered: Bool = {
        guard let url = Bundle.main.url(forResource: "SegoeUI", withExtension: "ttf") else { return false }
        return CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }()

    static func measuringFont(ofSize size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
        _ = registered
        if weight == .semibold, let font = NSFont(name: "SegoeUI-Semibold", size: size) { return font }
        guard let font = NSFont(name: "SegoeUI", size: size) else {
            return .systemFont(ofSize: size, weight: weight)
        }
        // A dedicated Semibold face can replace this synthesized weight when available.
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

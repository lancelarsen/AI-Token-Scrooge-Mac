import Foundation

/// One-unit keyboard adjustment in WinUI's degree/percentage channel units.
/// Spectrum channels wrap only after reaching an endpoint; the brightness
/// slider clamps. Adapted from Microsoft UI XAML ColorHelpers (MIT).
enum ColorPickerChannel {
    /// WinUI applies its default HSV bounds to RGB/Hex edits, before rounding
    /// back to bytes. Retain the fractional components so MaxHue359 remains
    /// exactly359 even when its displayed RGB rounds to255,0,4.
    static func rgbInputComponents(red: Int, green: Int, blue: Int)
        -> (hue: Double, saturation: Double, brightness: Double) {
        let r = Double(red) / 255, g = Double(green) / 255, b = Double(blue) / 255
        let high = max(r, g, b), low = min(r, g, b), chroma = high - low
        guard chroma > 0 else { return (0, 0, high) }
        var degrees: Double
        if high == r { degrees = 60 * (g - b) / chroma }
        else if high == g { degrees = 120 + 60 * (b - r) / chroma }
        else { degrees = 240 + 60 * (r - g) / chroma }
        if degrees < 0 { degrees += 360 }
        return (min(359, max(0, degrees)) / 360, chroma / high, high)
    }

    /// TextBox edits are drafts: reject invalid values rather than clamping
    /// them into a different color. WinUI restores the accepted value on blur.
    static func inputValue(_ text: String, maximum: Int) -> Int? {
        guard let value = Int(text.drop(while: { $0.isWhitespace })),
              (0...maximum).contains(value) else { return nil }
        return value
    }

    static func hexInput(_ text: String) -> String {
        let digits = text.hasPrefix("#") ? text.dropFirst() : text[...]
        return "#" + digits.prefix(6)
    }

    /// WinUI's opaque picker reads short Hex input as an integer (not CSS
    /// shorthand). An empty or malformed Hex input resolves to black.
    static func hexColor(_ text: String) -> String {
        var digits = String(hexInput(text).dropFirst().drop(while: { $0.isWhitespace }))
        let negative = digits.first == "-"
        if digits.first == "+" || negative { digits.removeFirst() }
        if digits.lowercased().hasPrefix("0x") { digits.removeFirst(2) }
        let parsed = UInt64(digits, radix: 16) ?? 0
        let value = (negative ? 0 &- parsed : parsed) & 0xFFFFFF
        return String(format: "#%06X", UInt32(value))
    }

    static func stepped(_ value: Double, maximum: Double, increasing: Bool, wraps: Bool) -> Double {
        let current = value.isFinite ? min(maximum, max(0, value)) : 0
        let next = current + (increasing ? 1 : -1)
        if next < 0 { return wraps && current == 0 ? maximum : 0 }
        if next > maximum { return wraps && current == maximum ? 0 : maximum }
        return next
    }

    /// WinUI's Ctrl+arrow moves to the midpoint of the next named color band.
    /// Scan the same HSV samples (1 degree or 0.01 saturation/value). The visit
    /// bound also covers hue at zero saturation, where every sample has one name.
    static func nextNamed(_ value: Double, maximum: Double, step: Double, increasing: Bool,
                          wraps: Bool, wrapPeriod: Double? = nil, name: (Double) -> String?) -> Double {
        guard let originalName = name(value) else { return value }
        let delta = increasing ? step : -step
        let visits = Int(ceil(maximum / step)) + 2
        func advance(_ from: Double) -> (value: Double, crossedEnd: Bool) {
            let next = from + delta
            if next > maximum { return (wraps ? 0 : maximum, true) }
            if next < 0 { return (wraps ? maximum : 0, true) }
            return (next, false)
        }

        var cursor = value
        for _ in 0..<visits {
            let next = advance(cursor)
            if next.crossedEnd && !wraps { return next.value }
            cursor = next.value
            guard let nextName = name(cursor) else { return value }
            if nextName == originalName { continue }

            let start = cursor
            var offset = 0.0
            for _ in 0..<visits {
                let end = advance(cursor)
                cursor = end.value
                if end.crossedEnd {
                    if !wraps { break }
                    offset = increasing ? maximum : -maximum
                }
                guard let currentName = name(cursor) else { return value }
                if currentName != nextName { break }
            }
            var middle = (start + cursor + offset) / 2
            // Match WinUI's rounding of the midpoint onto its channel grid.
            var remainder = abs(middle)
            while remainder > step { remainder -= step }
            middle -= remainder
            let period = wrapPeriod ?? maximum
            if middle < 0 { middle += period }
            if middle > maximum { middle -= period }
            return middle
        }
        return value
    }
}

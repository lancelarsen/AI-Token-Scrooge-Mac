import Foundation

/// One-unit keyboard adjustment in WinUI's degree/percentage channel units.
/// Spectrum channels wrap only after reaching an endpoint; the brightness
/// slider clamps. Adapted from Microsoft UI XAML ColorHelpers (MIT).
enum ColorPickerChannel {
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

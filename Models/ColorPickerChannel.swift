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
}

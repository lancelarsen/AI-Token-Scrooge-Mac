import Foundation

/// WinUI compares against the displayed spectrum (value = 1), rather than the
/// selected color's brightness. This keeps a dark selection visible on white.
/// Adapted from Microsoft UI XAML ColorSpectrum.SelectionEllipseShouldBeLight
/// (MIT); see Resources/MICROSOFT-UI-XAML-LICENSE.txt.
enum SpectrumSelectionContrast {
    static func usesLightStroke(hue: Double, saturation: Double) -> Bool {
        let h = hue.isFinite ? min(1, max(0, hue)) : 0
        let s = saturation.isFinite ? min(1, max(0, saturation)) : 0
        let sector = h * 6
        let fraction = sector - floor(sector)
        let pure: [Double]
        switch Int(sector) % 6 {
        case 0: pure = [1, fraction, 0]
        case 1: pure = [1 - fraction, 1, 0]
        case 2: pure = [0, 1, fraction]
        case 3: pure = [0, 1 - fraction, 1]
        case 4: pure = [fraction, 0, 1]
        default: pure = [1, 0, 1 - fraction]
        }
        let linear = pure.map { component -> Double in
            let channel = ((1 - s + s * component) * 255).rounded()
            return channel <= 10 ? channel / 3294 : pow(channel / 269 + 0.0513, 2.4)
        }
        return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2] <= 0.5
    }
}

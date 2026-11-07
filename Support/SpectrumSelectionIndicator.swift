import SwiftUI

/// Normal dark-theme ColorPicker slider thumb, measured in Windows run42376211522.
struct ColorBrightnessThumb: View {
    static let diameter: CGFloat = 20
    var body: some View {
        Circle().fill(Color(hex: "#454545")).padding(1)
            .overlay(Circle().fill(.white).frame(width: 10, height: 10))
            .frame(width: Self.diameter, height: Self.diameter)
    }
}

/// Native ColorPicker slider focus surrounds the full track, with a white
/// two-point outline and a one-point dark inner contrast stroke.
struct ColorBrightnessFocusOutline: View {
    var body: some View {
        Capsule().strokeBorder(.black.opacity(0.7), lineWidth: 3)
            .overlay(Capsule().strokeBorder(.white, lineWidth: 2))
    }
}

struct SpectrumSelectionIndicator: View {
    let light: Bool
    var hovered = false
    var pressed = false
    var keyboardFocused = false

    var body: some View {
        Circle().strokeBorder(light ? .white : .black, lineWidth: 2)
            .frame(width: 16, height: 16)
            .opacity(hovered && !pressed ? 0.8 : 1)
            .overlay {
                if keyboardFocused {
                    Circle().strokeBorder(light ? .black : .white, lineWidth: 2)
                        .frame(width: 20, height: 20)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

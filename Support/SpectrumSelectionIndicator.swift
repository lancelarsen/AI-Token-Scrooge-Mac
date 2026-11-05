import SwiftUI

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

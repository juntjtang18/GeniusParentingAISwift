import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.theme) var theme: Theme // 1. Read the current theme from the environment

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(theme.primary)
            .foregroundColor(theme.primaryText)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(theme.accent, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

// MARK: - Reusable Button Styles

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.theme) var theme: Theme // 1. Read the current theme from the environment
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.clear)
            .foregroundColor(theme.accent)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(theme.accent, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

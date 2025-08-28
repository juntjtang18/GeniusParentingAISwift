//
//  AppGradientBackground.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/8/28.
//


// AppGradientBackground.swift
import SwiftUI

struct AppGradientBackground: ViewModifier {
    @Environment(\.theme) var theme: Theme
    func body(content: Content) -> some View {
        ZStack {
            LinearGradient(
                colors: [theme.background2, theme.background],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            content
        }
    }
}

extension View {
    /// Use on any screen to get the global app gradient background.
    func appGradientBackground() -> some View {
        self.modifier(AppGradientBackground())
    }
}

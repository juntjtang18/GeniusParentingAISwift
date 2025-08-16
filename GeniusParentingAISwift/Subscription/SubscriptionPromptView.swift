//
//  SubscriptionPromptView.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/7/24.
//


//
//  SubscriptionPromptView.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/07/24.
//

import SwiftUI

struct SubscriptionPromptView: View {
    @Environment(\.theme) var theme: Theme
    
    /// Binding to control the visibility of this prompt view.
    @Binding var isPresented: Bool
    
    /// A closure that will be executed when the user taps the "Subscribe" button.
    let onSubscribe: () -> Void

    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Semi-transparent background to dim the content behind.
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { dismiss() } // Dismiss when tapping the background.

            VStack(spacing: 20) {
                // 1. Icon
                ZStack {
                    Circle()
                        .fill(theme.accent.opacity(0.2))
                        .frame(width: 80, height: 80)
                    Image(systemName: "star.fill")
                        .font(.system(size: 40))
                        .foregroundColor(theme.accent)
                }

                // 2. Title
                Text("Unlock Full Access")
                    .font(.title2).bold()
                    .foregroundColor(theme.foreground)

                // 3. Message
                Text("This course is only available to members. Subscribe now to unlock this and all other exclusive content!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // 4. Subscribe Button (Call to Action)
                Button(action: {
                    // First, dismiss this prompt.
                    dismiss()
                    // Then, execute the onSubscribe closure to show the subscription page.
                    onSubscribe()
                }) {
                    Text("Subscribe Now")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(theme.accent)
                        .clipShape(Capsule())
                }
                
                // 5. Dismiss Button
                Button("Maybe Later") {
                    dismiss()
                }
                .font(.footnote)
                .foregroundColor(.secondary)

            }
            .padding(30)
            .background(theme.background)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(40)
            .scaleEffect(isAnimating ? 1.0 : 0.95)
            .opacity(isAnimating ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isAnimating = true
                }
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isAnimating = false
        }
        // Allow the animation to complete before setting isPresented to false.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

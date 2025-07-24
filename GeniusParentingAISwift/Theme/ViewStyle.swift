// GeniusParentingAISwift/Theme/ViewStyle.swift
import SwiftUI

// 1. Define your style cases.
enum ViewStyle {
    case title, body, caption, primaryButton, secondaryButton, themedTextField, courseCard, homeSectionTitle,
         subscriptionCardTitle, subscriptionCardButton, subscriptionCardFeatureTitle, subscriptionCardFeatureItem,
         subscriptionPlanBadge,
         cardTitle // <-- NEW STYLE ADDED HERE
}

// 2. Conform exactly to ViewModifier—including @MainActor.
@MainActor
struct StyleModifier: ViewModifier {
    // 2a. Existential protocols work without the `any` keyword here.
    @Environment(\.theme) var theme: Theme
    let style: ViewStyle

    // 2b. Signature must match the protocol’s @MainActor requirement.
    @ViewBuilder
    func body(content: Content) -> some View {
        switch style {
        case .title:
            content
                .font(.largeTitle)
                .foregroundColor(theme.text)

        case .body:
            content
                .font(.body)
                .foregroundColor(theme.text)
        
        case .caption:
            content
                .font(.caption)
                .foregroundColor(theme.text.opacity(0.8))

        case .primaryButton:
            content
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(theme.primary)
                .foregroundColor(theme.text)
                .clipShape(Capsule())

        case .secondaryButton:
            content
                .foregroundColor(theme.secondary)

        case .themedTextField:
            content
                .padding()
                .background(theme.secondary.opacity(0.2))
                .cornerRadius(10)
                .foregroundColor(theme.text)
        
        case .courseCard:
            content
                .padding(EdgeInsets(top: 8, leading: 16, bottom: 12, trailing: 16))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(theme.cardBackground.opacity(0.7))
                
        case .homeSectionTitle:
            content
                .font(.title2.bold())
                .foregroundColor(theme.text)
                .padding(.horizontal)
        
        // --- STYLE TO MODIFY ---
        case .cardTitle:
            content
                .font(.subheadline) // <-- CHANGED FROM .body to .subheadline
                .foregroundColor(theme.text)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

        // ... (other styles remain unchanged)
        case .subscriptionCardTitle:
            content
                .font(.title3.bold())

        case .subscriptionCardButton:
            content
                .font(.subheadline)
        
        case .subscriptionCardFeatureTitle:
            content
                .font(.subheadline)

        case .subscriptionCardFeatureItem:
            content
                .font(.callout)
        
        case .subscriptionPlanBadge:
            content
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(theme.secondary)
                .foregroundColor(.white)
                .clipShape(Capsule())
        }
    }
}

// 3. Extension remains the same.
extension View {
    func style(_ style: ViewStyle) -> some View {
        self.modifier(StyleModifier(style: style))
    }
}

// A new, dedicated modifier for the subscription card's container style.
struct SubscriptionCardStyle: ViewModifier {
    let isHighlighted: Bool

    func body(content: Content) -> some View {
        content
            .padding(25)
            .background(isHighlighted ? Color(UIColor.systemGray6) : Color(UIColor.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func subscriptionCardStyle(isHighlighted: Bool) -> some View {
        self.modifier(SubscriptionCardStyle(isHighlighted: isHighlighted))
    }
}

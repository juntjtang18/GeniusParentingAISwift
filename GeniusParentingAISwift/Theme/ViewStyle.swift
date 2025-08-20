// GeniusParentingAISwift/Theme/ViewStyle.swift
import SwiftUI

// 1. Define your style cases.
enum ViewStyle {
    case title, body, caption, primaryButton, secondaryButton, themedTextField, courseCard, homeSectionTitle,
         subscriptionCardTitle, subscriptionCardButton, subscriptionCardFeatureTitle, subscriptionCardFeatureItem,
         subscriptionPlanBadge,
         // ADDED: New text styles for home screen cards
         lessonCardTitle, hotTopicCardTitle, dailyTipCardTitle
}

// 2. Conform exactly to ViewModifier—including @MainActor.
@MainActor
struct StyleModifier: ViewModifier {
    @Environment(\.theme) var theme: Theme
    let style: ViewStyle

    @ViewBuilder
    func body(content: Content) -> some View {
        switch style {
        case .title:
            content
                .font(.largeTitle)
                .foregroundColor(theme.foreground)

        case .body:
            content
                .font(.body)
                .foregroundColor(theme.foreground)
        
        case .caption:
            content
                .font(.caption)
                .foregroundColor(theme.foreground.opacity(0.8))

        case .primaryButton:
            content
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(theme.primary)
                .foregroundColor(theme.accentSecond)
                .clipShape(Capsule())

        case .secondaryButton:
            content
                .foregroundColor(theme.foreground)

        case .themedTextField:
            content
                .padding()
                .background(theme.foreground.opacity(0.2))
                .cornerRadius(10)
                .foregroundColor(theme.foreground)
        
        case .courseCard:
            content
                .padding(EdgeInsets(top: 8, leading: 16, bottom: 12, trailing: 16))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(theme.background.opacity(0.7))
                
        case .homeSectionTitle:
            content
                .font(.title2.bold())
                .foregroundColor(theme.foreground)
                .padding(.horizontal)
        
        case .lessonCardTitle:
            content
                .font(.headline.weight(.regular))   // was .headline (semibold)
                .foregroundColor(theme.foreground)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

        case .hotTopicCardTitle:
            content
                .font(.subheadline.weight(.regular)) // was .subheadline.weight(.bold)
                .foregroundColor(theme.foreground)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

        case .dailyTipCardTitle:
            content
                .font(.callout.weight(.regular))     // was .callout (semibold by default on some devices)
                .foregroundColor(theme.foreground)
                .lineLimit(3)
                .multilineTextAlignment(.leading)


        case .subscriptionCardTitle:
            content.font(.title3.bold())

        case .subscriptionCardButton:
            content.font(.subheadline)
        
        case .subscriptionCardFeatureTitle:
            content.font(.subheadline)

        case .subscriptionCardFeatureItem:
            content.font(.callout)
        
        case .subscriptionPlanBadge:
            content
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(theme.foreground)
                .foregroundColor(.white)
                .clipShape(Capsule())
        }
    }
}

// 3. Extension
extension View {
    func style(_ style: ViewStyle) -> some View {
        self.modifier(StyleModifier(style: style))
    }
}

// MARK: - Home Card Styles
struct NewLessonCardStyle: ViewModifier {
    @Environment(\.theme) var theme: Theme
    @Environment(\.appDimensions) var dims

    // Single source of truth for sizing
    private var cardWidth: CGFloat { dims.screenSize.width * 0.85 }
    private var cardHeight: CGFloat { cardWidth * 0.62 }

    func body(content: Content) -> some View {
        content
            .frame(width: cardWidth, height: cardHeight)
            .background(theme.accentBackground)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
    }
}

struct LessonCardStyle: ViewModifier {
    @Environment(\.theme) var theme: Theme
    @Environment(\.appDimensions) var dims

    private var cardWidth: CGFloat { dims.screenSize.width * 0.85 }
    private var cardHeight: CGFloat { cardWidth * 0.62 }

    func body(content: Content) -> some View {
        content
            .frame(width: cardWidth, height: cardHeight)
            .background(theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 4)
    }
}

struct HotTopicCardStyle: ViewModifier {
    @Environment(\.theme) var theme: Theme
    func body(content: Content) -> some View {
        content
            .frame(width: 300, height: 250)
            .background(theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(color: theme.accent.opacity(0.3), radius: 6, x: 0, y: 5)
    }
}

struct DailyTipCardStyle: ViewModifier {
    @Environment(\.theme) var theme: Theme
    func body(content: Content) -> some View {
        content
            .frame(width: 300, height: 250)
            .background(theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func newLessonCardStyle() -> some View { self.modifier(NewLessonCardStyle()) }
    func lessonCardStyle() -> some View { self.modifier(LessonCardStyle()) }
    func hotTopicCardStyle() -> some View { self.modifier(HotTopicCardStyle()) }
    func dailyTipCardStyle() -> some View { self.modifier(DailyTipCardStyle()) }
}

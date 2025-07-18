// GeniusParentingAISwift/DailyTipCardView.swift
import SwiftUI

struct DailyTipCardView: View {
    @Environment(\.theme) var theme: Theme
    let tip: Tip
    private let cardHeight: CGFloat = 250

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top part: Image
            Group {
                if let iconMedia = tip.iconImageMedia, let imageUrl = URL(string: iconMedia.attributes.url) {
                    CachedAsyncImage(url: imageUrl)
                } else {
                    theme.cardBackground
                        .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray))
                }
            }
            .frame(height: cardHeight * 3 / 5)
            .frame(maxWidth: .infinity)
            .clipped()

            // Bottom part: Title
            Text(tip.text)
                .lineLimit(3) // Allow more lines for tips
                .multilineTextAlignment(.leading)
                .frame(height: cardHeight * 2 / 5)
                .style(.courseCard)
        }
        .frame(width: 300, height: cardHeight)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .clipped()
    }
}

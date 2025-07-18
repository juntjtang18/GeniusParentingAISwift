// GeniusParentingAISwift/HotTopicCardView.swift
import SwiftUI

struct HotTopicCardView: View {
    @Environment(\.theme) var theme: Theme
    let topic: Topic
    private let cardHeight: CGFloat = 250

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top part: Image
            Group {
                if let iconMedia = topic.iconImageMedia, let imageUrl = URL(string: iconMedia.attributes.url) {
                    CachedAsyncImage(url: imageUrl)
                } else {
                    theme.cardBackground
                        .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray))
                }
            }
            .frame(height: cardHeight * 3 / 5)
            .frame(maxWidth: .infinity)
            .clipped()

            // Bottom part: Title and Play Button
            HStack(alignment: .center) {
                Text(topic.title)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()

                // Play Button
                ZStack {
                    Circle()
                        .fill(theme.accent)
                    Image(systemName: "play.fill")
                        .foregroundColor(theme.cardBackground)
                        .font(.system(size: 20))
                }
                .frame(width: 50, height: 50)
            }
            .frame(height: cardHeight * 2 / 5)
            .style(.courseCard)
        }
        .frame(width: 300, height: cardHeight)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .clipped()
    }
}

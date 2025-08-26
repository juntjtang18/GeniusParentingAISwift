// GeniusParentingAISwift/Home/HotTopicCardView.swift
import SwiftUI

struct HotTopicCardView: View {
    @Environment(\.theme) var currentTheme: Theme
    let topic: Topic

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                // --- IMAGE SECTION ---
                Group {
                    if let iconMedia = topic.iconImageMedia, let imageUrl = URL(string: iconMedia.attributes.url) {
                        CachedAsyncImage(url: imageUrl)
                    } else {
                        currentTheme.background
                            .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray))
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height * 0.7)
                .clipped()

                // --- TITLE SECTION ---
                HStack(alignment: .center) {
                    Text(topic.title)
                        .font(.subheadline.weight(.regular)) // was .subheadline.weight(.bold)
                        .foregroundColor(currentTheme.accent)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)


                    Spacer()

                    PlayButtonView()

                }
                .style(.courseCard) // This style handles padding and background
            }
        }
        .hotTopicCardStyle() // <-- USE THE NEW CONTAINER STYLE
    }
}

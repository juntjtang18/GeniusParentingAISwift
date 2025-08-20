// GeniusParentingAISwift/Home/HotTopicCardView.swift
import SwiftUI

struct HotTopicCardView: View {
    @Environment(\.theme) var theme: Theme
    let topic: Topic

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                // --- IMAGE SECTION ---
                Group {
                    if let iconMedia = topic.iconImageMedia, let imageUrl = URL(string: iconMedia.attributes.url) {
                        CachedAsyncImage(url: imageUrl)
                    } else {
                        theme.background
                            .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray))
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height * 0.7)
                .clipped()

                // --- TITLE SECTION ---
                HStack(alignment: .center) {
                    Text(topic.title)
                        .style(.hotTopicCardTitle) // <-- USE THE NEW STYLE

                    Spacer()

                    ZStack {
                        Circle().fill(theme.accent)
                        Image(systemName: "play.fill")
                            .foregroundColor(theme.background)
                            .font(.system(size: 20))
                    }
                    .frame(width: 50, height: 50)
                }
                .style(.courseCard) // This style handles padding and background
            }
        }
        .hotTopicCardStyle() // <-- USE THE NEW CONTAINER STYLE
    }
}

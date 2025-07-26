// GeniusParentingAISwift/Home/DailyTipCardView.swift
import SwiftUI

struct DailyTipCardView: View {
    @Environment(\.theme) var theme: Theme
    let tip: Tip

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                // --- IMAGE SECTION ---
                Group {
                    if let iconMedia = tip.iconImageMedia, let imageUrl = URL(string: iconMedia.attributes.url) {
                        CachedAsyncImage(url: imageUrl)
                    } else {
                        theme.cardBackground
                            .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray))
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height * 0.7)
                .clipped()

                // --- TITLE SECTION ---
                HStack(alignment: .center) {
                    Text(tip.text)
                        .style(.dailyTipCardTitle) // <-- USE THE NEW STYLE

                    Spacer()
                }
                .style(.courseCard) // This style handles padding and background
            }
        }
        .dailyTipCardStyle() // <-- USE THE NEW CONTAINER STYLE
    }
}

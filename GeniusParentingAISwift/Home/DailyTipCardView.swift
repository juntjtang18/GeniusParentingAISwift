// GeniusParentingAISwift/DailyTipCardView.swift
import SwiftUI

struct DailyTipCardView: View {
    @Environment(\.theme) var theme: Theme
    let tip: Tip
    private let cardHeight: CGFloat = 250

    var body: some View {
        // By wrapping our content in a GeometryReader, we get a reliable parent size.
        GeometryReader { geometry in
            
            // This VStack is now inside the GeometryReader, which makes its layout stable.
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
                        .style(.cardTitle) // <-- USE THE NEW STYLE

                    Spacer()
                }
                .style(.courseCard) // This style now only handles padding and background
            }
        }
        // The final modifiers are applied to the GeometryReader container.
        .frame(width: 300, height: cardHeight)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .clipped()
    }
}

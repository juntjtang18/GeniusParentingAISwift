// GeniusParentingAISwift/Home/DailyTipCardView.swift
import SwiftUI

struct DailyTipCardView: View {
    @Environment(\.theme) var currentTheme: Theme
    let tip: Tip

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                // --- IMAGE SECTION ---
                Group {
                    if let iconMedia = tip.iconImageMedia, let imageUrl = URL(string: iconMedia.attributes.url) {
                        CachedAsyncImage(url: imageUrl)
                    } else {
                        currentTheme.accentBackground
                            .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(currentTheme.accent))
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height * 0.7)
                .clipped()

                // --- TITLE SECTION ---
                HStack(alignment: .center) {
                    Text(tip.text)
                        .style(.dailyTipCardTitle)

                    Spacer()
                }
                .padding(EdgeInsets(top: 8, leading: 16, bottom: 12, trailing: 16))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(currentTheme.accentBackground.opacity(1))
            }
        }
        .dailyTipCardStyle() // <-- USE THE NEW CONTAINER STYLE
        //.frame(width: 300, height: 250)
        //.background(currentTheme.accentBackground)
        //.clipShape(RoundedRectangle(cornerRadius: 25))
        //.shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

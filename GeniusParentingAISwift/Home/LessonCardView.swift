// GeniusParentingAISwift/LessonCardView.swift
import SwiftUI

struct LessonCardView: View {
    @Environment(\.theme) var theme: Theme
    let lesson: LessonCourse
    private let cardHeight: CGFloat = 250

    var body: some View {
        // By wrapping our content in a GeometryReader, we get a reliable parent size.
        GeometryReader { geometry in
            
            // This VStack is now inside the GeometryReader, which makes its layout stable.
            VStack(alignment: .leading, spacing: 0) {
                
                // --- IMAGE SECTION ---
                Group {
                    if let iconMedia = lesson.attributes.icon_image?.data, let imageUrl = URL(string: iconMedia.attributes.url) {
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
                    Text(lesson.attributes.title)
                        .style(.cardTitle) // <-- USE THE NEW STYLE

                    Spacer()

                    ZStack {
                        Circle().fill(theme.accent)
                        Image(systemName: "play.fill")
                            .foregroundColor(theme.cardBackground)
                            .font(.system(size: 20))
                    }
                    .frame(width: 50, height: 50)
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

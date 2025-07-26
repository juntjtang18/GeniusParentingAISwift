// GeniusParentingAISwift/Home/LessonCardView.swift
import SwiftUI

struct LessonCardView: View {
    @Environment(\.theme) var theme: Theme
    let lesson: LessonCourse

    var body: some View {
        GeometryReader { geometry in
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
                        .style(.lessonCardTitle) // <-- USE THE NEW STYLE

                    Spacer()

                    ZStack {
                        Circle().fill(theme.accent)
                        Image(systemName: "play.fill")
                            .foregroundColor(theme.cardBackground)
                            .font(.system(size: 20))
                    }
                    .frame(width: 50, height: 50)
                }
                .style(.courseCard) // This style handles padding and background
            }
        }
        .lessonCardStyle() // <-- USE THE NEW CONTAINER STYLE
    }
}

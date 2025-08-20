// LessonCardView.swift
import SwiftUI

struct LessonCardView: View {
    @Environment(\.theme) var theme: Theme
    @Environment(\.appDimensions) private var dims
    let lesson: LessonCourse

    private var cardWidth: CGFloat { dims.screenSize.width * 0.85 }
    private var cardHeight: CGFloat { cardWidth * 0.62 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // IMAGE
            Group {
                if let iconMedia = lesson.attributes.icon_image?.data,
                   let imageUrl = URL(string: iconMedia.attributes.url) {
                    CachedAsyncImage(url: imageUrl)
                        .scaledToFill()
                } else {
                    theme.background
                        .overlay(Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray))
                }
            }
            .frame(height: cardHeight * 0.7)
            .clipped()

            // TITLE ROW
            HStack(alignment: .center) {
                Text(lesson.attributes.title)
                    .style(.lessonCardTitle)
                    .foregroundColor(theme.primaryText)

                Spacer()

                PlayButtonView()

            }
            .style(.courseCard)
        }
        .newLessonCardStyle()
    }
}

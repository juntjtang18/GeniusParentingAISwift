// LessonCardView.swift
import SwiftUI

struct LessonCardView: View {
    @Environment(\.theme) var theme: Theme
    let lesson: LessonCourse
    
    let cardWidth: CGFloat
    let cardHeight: CGFloat

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
                    .font(.subheadline.weight(.regular)) // was .subheadline.weight(.bold)
                    .foregroundColor(theme.foreground)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()

                PlayButtonView()
            }
            .padding(EdgeInsets(top: 8, leading: 16, bottom: 12, trailing: 16))
            // MODIFIED: Changed alignment from .top to .center to vertically center the content.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background(theme.background.opacity(0.7))
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(theme.accentBackground)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
    }
}

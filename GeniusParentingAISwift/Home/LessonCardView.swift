// LessonCardView.swift
import SwiftUI

struct LessonCardView: View {
    @Environment(\.theme) var theme: Theme
    let lesson: LessonCourse

    let cardWidth: CGFloat
    let cardHeight: CGFloat

    // Keep the image a fixed portion of the card height.
    private var imageHeight: CGFloat { cardHeight * 0.65 }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Image section
            Group {
                if let iconMedia = lesson.attributes.icon_image?.data,
                   let imageUrl = URL(string: iconMedia.attributes.url) {
                    AsyncImage(url: imageUrl) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        case .empty:
                            ProgressView()
                        case .failure:
                            Image(systemName: "photo")
                                .resizable().scaledToFit()
                                .padding(24)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "photo")
                        .resizable().scaledToFit()
                        .padding(24)
                }
            }
            .frame(height: imageHeight)
            .frame(maxWidth: .infinity)
            .clipped()

            // TITLE + PLAY ROW
            HStack(spacing: 12) {
                Text(lesson.attributes.title)
                    .font(.subheadline)
                    .foregroundColor(theme.accent)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true) // let text expand if 2 lines

                PlayButtonView()
                    .frame(width: 36, height: 36) // keeps button centered
            }
            //.frame(height: 60)                      // fixed row height
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, 16)
            .background(theme.accentBackground)

        }
        .frame(width: cardWidth, height: cardHeight, alignment: .top)
        .background(theme.accentBackground)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
    }
}

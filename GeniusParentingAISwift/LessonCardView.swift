import SwiftUI

struct LessonCardView: View {
    let lesson: LessonCourse

    var body: some View {
        // The foreground overlay (gradient and title) remains the same.
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                gradient: Gradient(colors: [.clear, .clear, .black.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )

            Text(lesson.attributes.title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()
        }
        // Use a more robust AsyncImage initializer for the background.
        .background(
            AsyncImage(
                url: URL(string: lesson.attributes.iconImage?.data?.attributes.url ?? ""),
                content: { image in
                    // This is the view that will be shown on successful image load.
                    image
                        .resizable()
                        // This modifier is the key: it scales the image to fill the entire
                        // frame, cropping excess parts. The .clipped() modifier below will
                        // then trim the image to the card's rounded corners.
                        .aspectRatio(contentMode: .fill)
                },
                placeholder: {
                    // This placeholder is shown during loading or if the URL is invalid/fails.
                    ZStack {
                        Color(UIColor.secondarySystemBackground)
                        ProgressView()
                    }
                }
            )
        )
        .frame(width: 375, height: 150)
        .cornerRadius(12)
        .clipped()
    }
}

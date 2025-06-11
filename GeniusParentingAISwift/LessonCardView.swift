import SwiftUI

struct LessonCardView: View {
    let lesson: LessonCourse

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                gradient: Gradient(colors: [.clear, .clear, .black.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )

            Text(lesson.attributes.title)
                .font(.headline)
                .foregroundColor(.white)
                .padding()
        }
        .background(
            AsyncImage(
                url: URL(string: lesson.attributes.iconImage?.data?.attributes.url ?? ""),
                content: { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                },
                placeholder: {
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

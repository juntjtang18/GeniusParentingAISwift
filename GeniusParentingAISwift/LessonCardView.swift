import SwiftUI

struct LessonCardView: View {
    let lesson: LessonCourse

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let iconUrl = lesson.attributes.iconImage?.data?.attributes.url, let url = URL(string: iconUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                    case .failure(_):
                        Image(systemName: "photo") // Placeholder on failure
                            .resizable()
                    default:
                        ProgressView()
                    }
                }
            } else {
                Image("lessonImage") // Default placeholder
                    .resizable()
            }

            VStack(alignment: .leading) {
                Text(lesson.attributes.title)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
        }
        .frame(width: 250, height: 150)
        .background(Color.gray)
        .cornerRadius(10)
        .clipped()
    }
}

import SwiftUI

struct HotTopicCardView: View {
    let topic: Topic

    var body: some View {
        // --- REFACTORED for more robust layout ---
        ZStack(alignment: .bottomLeading) {
            // The ZStack now only contains foreground content.
            
            // 1. Gradient Layer
            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
                startPoint: .center,
                endPoint: .bottom
            )

            // 2. Text Layer (guaranteed to be on top of the gradient)
            Text(topic.title)
                .font(.headline)
                .foregroundColor(.white)
                .padding()
        }
        .frame(width: 250, height: 150)
        // 3. The Image is now applied as the background of the ZStack.
        .background(
            AsyncImage(url: URL(string: topic.iconImageMedia?.urlString ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                         .aspectRatio(contentMode: .fill)
                case .failure, .empty:
                    // Show a gray placeholder for loading or failure.
                    Rectangle().foregroundColor(.gray.opacity(0.5))
                @unknown default:
                    EmptyView()
                }
            }
        )
        .cornerRadius(12)
        .clipped() // Use .clipped() to ensure the image respects the corner radius.
        .shadow(radius: 5)
    }
}

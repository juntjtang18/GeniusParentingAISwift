import SwiftUI

struct DailyTipCardView: View {
    let tip: Tip

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Gradient overlay for text readability
            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
                startPoint: .center,
                endPoint: .bottom
            )

            // Tip text
            Text(tip.text)
                .font(.headline)
                .foregroundColor(.white)
                .padding()
        }
        .frame(width: 250, height: 150)
        .background(
            AsyncImage(url: URL(string: tip.iconImageMedia?.urlString ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                         .aspectRatio(contentMode: .fill)
                case .failure, .empty:
                    // Gray placeholder on failure or while loading
                    Rectangle().foregroundColor(.gray.opacity(0.5))
                @unknown default:
                    EmptyView()
                }
            }
        )
        .cornerRadius(12)
        .clipped() // Ensures the image respects the corner radius
        .shadow(radius: 5)
        .padding(5) // Add padding to increase tappable area
        .contentShape(Rectangle()) // Ensure the entire view, including padding, is tappable
    }
}

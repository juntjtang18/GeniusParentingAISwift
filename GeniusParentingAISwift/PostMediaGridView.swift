// PostMediaGridView.swift

import SwiftUI

struct PostMediaGridView: View {
    let media: [Media]
    private let spacing: CGFloat = 4

    var body: some View {
        // A post can have at most 9 images, so we take the first 9.
        let displayMedia = Array(media.prefix(9))

        if displayMedia.isEmpty {
            EmptyView()
        } else {
            let columns = makeColumns(count: displayMedia.count)
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(displayMedia) { mediaItem in
                    renderImage(for: mediaItem)
                        // Make grid items square
                        .aspectRatio(1, contentMode: .fill)
                }
            }
        }
    }

    /// Determines the number of columns for the grid.
    /// Uses 2 columns for 2 or 4 images for a more balanced look.
    /// Uses 3 columns for all other counts (3, 5, 6, 7, 8, 9).
    private func makeColumns(count: Int) -> [GridItem] {
        let columnCount = (count == 2 || count == 4) ? 2 : 3
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
    }

    /// Renders a single image using AsyncImage.
    /// It prefers smaller image formats for performance and provides placeholders.
    @ViewBuilder
    private func renderImage(for mediaItem: Media) -> some View {
        // Prioritize 'medium' or 'small' format for better performance in a list.
        // Fall back to the original URL if other formats aren't available.
        let urlString = mediaItem.attributes.formats?.medium?.url
                     ?? mediaItem.attributes.formats?.small?.url
                     ?? mediaItem.attributes.url
        
        if let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                case .failure:
                    // Display a placeholder icon if the image fails to load
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.largeTitle)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGray5))
                case .empty:
                    // Display a gray placeholder while the image is loading
                    Rectangle()
                        .foregroundColor(Color(.systemGray6))
                @unknown default:
                    EmptyView()
                }
            }
            .clipped()
            .cornerRadius(8)
        }
    }
}

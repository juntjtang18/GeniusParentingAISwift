// GeniusParentingAISwift/PostMediaGridView.swift
import SwiftUI

struct PostMediaGridView: View {
    let media: [Media]
    private let spacing: CGFloat = 4

    var body: some View {
        // A post can have at most 9 images, so we take the first 9.
        let displayMedia = Array(media.prefix(9))

        if displayMedia.isEmpty {
            EmptyView()
        } else if displayMedia.count == 1 {
            // --- 1. SPECIAL CASE: SINGLE IMAGE ---
            // If there's only one image, we display it while preserving its original aspect ratio.
            if let firstMedia = displayMedia.first {
                renderImage(for: firstMedia)
                    // Use width/height from the API to calculate the aspect ratio.
                    // .fit ensures the entire image is visible without being cropped.
                    .aspectRatio(calculateAspectRatio(for: firstMedia.attributes), contentMode: .fit)
                    .cornerRadius(8)
                    .clipped()
            }
        } else {
            // --- 2. DEFAULT CASE: MULTI-IMAGE GRID ---
            // For 2 or more images, we create a uniform grid of square thumbnails.
            let columns = makeColumns(count: displayMedia.count)
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(displayMedia) { mediaItem in
                    renderImage(for: mediaItem)
                        // Forcing a 1:1 ratio makes the grid look neat and tidy.
                        // .fill crops the image to fill the square space.
                        .aspectRatio(1, contentMode: .fill)
                        .cornerRadius(8)
                        .clipped()
                }
            }
        }
    }

    /// Determines the number of columns for the grid.
    private func makeColumns(count: Int) -> [GridItem] {
        let columnCount = (count == 2 || count == 4) ? 2 : 3
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
    }

    /// Calculates the aspect ratio from media metadata to prevent UI layout shifts.
    private func calculateAspectRatio(for attributes: Media.MediaAttributes) -> CGFloat? {
        if let width = attributes.width, let height = attributes.height, height > 0 {
            return CGFloat(width) / CGFloat(height)
        }
        // If metadata is missing, return nil so the view can adapt once the image loads.
        return nil
    }

    /// Renders a single image using AsyncImage with placeholders.
    @ViewBuilder
    private func renderImage(for mediaItem: Media) -> some View {
        let urlString = mediaItem.attributes.formats?.medium?.url
                     ?? mediaItem.attributes.formats?.small?.url
                     ?? mediaItem.attributes.url
        
        if let url = URL(string: urlString) {
            CachedAsyncImage(url: url)
        }
    }
}

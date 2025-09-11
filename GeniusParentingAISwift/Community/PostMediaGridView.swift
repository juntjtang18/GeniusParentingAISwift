// GeniusParentingAISwift/PostMediaGridView.swift
import SwiftUI

struct PostMediaGridView: View {
    let media: [Media]
    private let spacing: CGFloat = 4

    var body: some View {
        let displayMedia = Array(media.prefix(9))

        if displayMedia.isEmpty {
            EmptyView()
        } else if displayMedia.count == 1 {
            // Single image: preserve original aspect ratio and make it resizable.
            if let firstMedia = displayMedia.first {
                SingleImageView(mediaItem: firstMedia)
            }
        } else {
            // Multi-image: uniform square thumbnails.
            let columns = makeColumns(count: displayMedia.count)
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(displayMedia) { mediaItem in
                    SquareThumbnail(urlString: bestURLString(for: mediaItem))
                }
            }
        }
    }

    private func makeColumns(count: Int) -> [GridItem] {
        let columnCount = (count == 2 || count == 4) ? 2 : 3
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
    }

    private func bestURLString(for mediaItem: Media) -> String {
        mediaItem.attributes.formats?.medium?.url
        ?? mediaItem.attributes.formats?.small?.url
        ?? mediaItem.attributes.url
    }
}

/// A square, fill-cropped thumbnail that ALWAYS uses a resizable image.
private struct SquareThumbnail: View {
    let urlString: String

    var body: some View {
        // 1) A square container whose height is always equal to the column width
        Rectangle()
            .fill(Color.clear)
            .aspectRatio(1, contentMode: .fit)        // <- makes a square box
            .frame(maxWidth: .infinity)               // <- expand to fill the grid column width

            // 2) Put the (resizable) image *inside* that fixed square
            .overlay {
                if let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()       // fill the square; cropping is fine for thumbs
                        case .failure:
                            placeholder
                        case .empty:
                            placeholder
                        @unknown default:
                            placeholder
                        }
                    }
                    .clipped()                        // clip to the square box
                } else {
                    placeholder
                        .clipped()
                }
            }

            // 3) Rounded corners last so they apply to the final square
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.secondary.opacity(0.08))
            Image(systemName: "photo")
                .imageScale(.large)
                .foregroundColor(.secondary.opacity(0.6))
        }
    }
}


/// A single image view preserving the original aspect ratio from metadata when available.
private struct SingleImageView: View {
    let mediaItem: Media

    var body: some View {
        let attrs = mediaItem.attributes
        let ratio: CGFloat? = {
            if let w = attrs.width, let h = attrs.height, h > 0 {
                return CGFloat(w) / CGFloat(h)
            }
            return nil
        }()

        if let url = URL(string: attrs.formats?.medium?.url
                         ?? attrs.formats?.small?.url
                         ?? attrs.url) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()                           // <-- IMPORTANT
                        .scaledToFit()                         // Preserve aspect ratio without cropping
                case .failure:
                    singlePlaceholder
                case .empty:
                    singlePlaceholder
                @unknown default:
                    singlePlaceholder
                }
            }
            .aspectRatio(ratio, contentMode: .fit)              // If nil, SwiftUI adapts after load
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var singlePlaceholder: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(.secondary.opacity(0.08))
            .frame(height: 200)
            .overlay(
                ProgressView().progressViewStyle(.circular)
            )
    }
}

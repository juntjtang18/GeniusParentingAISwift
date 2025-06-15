import SwiftUI

struct RichTextView: View {
    let html: String
    
    // State to hold the parsed content blocks. It's optional, starting as nil.
    @State private var contentBlocks: [ContentBlock]? = nil

    var body: some View {
        // If content has been parsed, display it.
        if let blocks = contentBlocks {
            VStack(alignment: .leading, spacing: 15) {
                // The ForEach loop is now guaranteed to run on pre-parsed, simple data.
                ForEach(blocks) { contentBlock in
                    switch contentBlock.type {
                    case .text(let nsAttributedString):
                        Text(AttributedString(nsAttributedString))
                            .font(.body)
                    case .image(let url):
                        HStack {
                            Spacer()
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().aspectRatio(contentMode: .fit).cornerRadius(8)
                                case .failure:
                                    Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray)
                                case .empty:
                                    ProgressView()
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
        } else {
            // If content has not been parsed yet, show a loading spinner.
            // When it appears, trigger the asynchronous parsing.
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .center)
                .onAppear(perform: parseHTML)
        }
    }
    
    // This function now starts the asynchronous parsing task.
    private func parseHTML() {
        // Run the entire parsing operation in a background task.
        Task(priority: .userInitiated) {
            let blocks = await Self.createContentBlocks(from: html)
            
            // Switch back to the main thread to update the UI state.
            await MainActor.run {
                self.contentBlocks = blocks
            }
        }
    }

    // This function now performs the actual parsing work and is marked as 'async'.
    private static func createContentBlocks(from html: String) async -> [ContentBlock] {
        var blocks: [ContentBlock] = []
        let imgRegex = try! NSRegularExpression(pattern: "<img[^>]+src\\s*=\\s*['\"]([^'\"]+)['\"][^>]*>", options: .caseInsensitive)
        
        let matches = imgRegex.matches(in: html, options: [], range: NSRange(location: 0, length: html.utf16.count))
        
        var lastRangeEnd = 0
        
        for match in matches {
            let textRange = NSRange(location: lastRangeEnd, length: match.range.location - lastRangeEnd)
            if let swiftRange = Range(textRange, in: html) {
                let textHtml = String(html[swiftRange])
                if let attributedString = convertHtmlToAttributedString(textHtml),
                   !attributedString.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    blocks.append(ContentBlock(type: .text(attributedString)))
                }
            }
            
            if let srcRange = Range(match.range(at: 1), in: html) {
                let urlString = String(html[srcRange])
                if let url = URL(string: urlString) {
                    blocks.append(ContentBlock(type: .image(url)))
                }
            }
            
            lastRangeEnd = match.range.upperBound
        }
        
        let remainingRange = NSRange(location: lastRangeEnd, length: html.utf16.count - lastRangeEnd)
        if let swiftRange = Range(remainingRange, in: html) {
            let textHtml = String(html[swiftRange])
            if let attributedString = convertHtmlToAttributedString(textHtml),
               !attributedString.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                blocks.append(ContentBlock(type: .text(attributedString)))
            }
        }
        
        if blocks.isEmpty, let attributedString = convertHtmlToAttributedString(html) {
            blocks.append(ContentBlock(type: .text(attributedString)))
        }

        return blocks
    }

    private static func convertHtmlToAttributedString(_ html: String) -> NSAttributedString? {
        guard let data = html.data(using: .utf8) else { return nil }
        return try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil
        )
    }
    
    // --- Helper Structs ---
    private struct ContentBlock: Identifiable {
        let id = UUID()
        let type: ContentType
    }
    
    private enum ContentType {
        case text(NSAttributedString)
        case image(URL)
    }
}

import SwiftUI
import AVFoundation // For AVSpeechSynthesizer
import WebKit // For VideoPlayerWebView

// Actual definitions for Content, Content.Styles, and Color(hex:)
// are expected to be in your project's model files.

struct ContentView: View {
    let content: Content
    let language: String // For speech synthesis language
    @StateObject private var speechManager = SpeechManager()
    @State private var selectedQuizOption: String? // For quiz interaction
    @Binding var webView: WKWebView? // Use binding to avoid state modification issues

    var body: some View {
        VStack(alignment: alignmentFor(content.styles?.textAlign), spacing: 8) {
            switch content.__component {
            case "content.text":
                if let textData = content.data, !textData.isEmpty {
                    Text(textData)
                        .font(.system(size: content.styles?.fontSize ?? 16,
                                      weight: content.styles?.isBold == true ? .bold : .regular))
                        .italic(content.styles?.isItalic == true)
                        .foregroundColor(Color(hex: content.styles?.fontColor ?? "#000000"))
                        .multilineTextAlignment(textAlignmentFor(content.styles?.textAlign))
                        .frame(maxWidth: .infinity, alignment: frameAlignmentFor(content.styles?.textAlign))
                        .padding(.horizontal)
                }
            case "content.image":
                if let imageUrlString = content.url, let imageUrl = URL(string: imageUrlString) {
                    AsyncImage(url: imageUrl) { phase in
                        switch phase {
                        case .empty: ProgressView().frame(height: 200)
                        case .success(let image): image.resizable().aspectRatio(contentMode: .fit).cornerRadius(8)
                        case .failure: Image(systemName: "photo.fill.on.rectangle.fill").resizable().aspectRatio(contentMode: .fit).frame(height:100).foregroundColor(.gray)
                        @unknown default: EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity).frame(height: 200).padding(.horizontal)
                } else {
                    Text("Image URL invalid/missing.").foregroundColor(.red).padding()
                }
            case "content.video":
                if let videoUrlString = content.url, !videoUrlString.isEmpty {
                    let finalVideoUrl = getEmbeddableVideoURL(from: videoUrlString, autoPlay: true)
                    if let finalVideoUrl = finalVideoUrl {
                        VideoPlayerWebView(urlString: finalVideoUrl.absoluteString, webView: $webView)
                            .frame(height: 250)
                            .cornerRadius(8)
                            .padding(.horizontal)
                            .onAppear {
                                // Resume playback if webView exists
                                if let webView = webView {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        webView.evaluateJavaScript("document.querySelector('iframe').contentWindow.postMessage('{\"event\":\"command\",\"func\":\"playVideo\",\"args\":\"\"}', '*')") { _, error in
                                            if let error = error {
                                                print("JavaScript play error: \(error)")
                                            } else {
                                                print("VideoPlayerWebView: Resuming video on appear")
                                            }
                                        }
                                    }
                                }
                            }
                            .onDisappear {
                                // Pause playback if webView exists
                                if let webView = webView {
                                    webView.evaluateJavaScript("document.querySelector('iframe').contentWindow.postMessage('{\"event\":\"command\",\"func\":\"pauseVideo\",\"args\":\"\"}', '*')") { _, error in
                                        if let error = error {
                                            print("JavaScript pause error: \(error)")
                                        } else {
                                            print("VideoPlayerWebView: Pausing video on disappear")
                                        }
                                    }
                                }
                            }
                    } else {
                        Text("Video URL is invalid.").foregroundColor(.red).padding()
                    }
                } else {
                    Text("Video URL is missing.").foregroundColor(.red).padding()
                }
            case "content.quiz":
                VStack(alignment: .leading, spacing: 12) {
                    if let questionText = content.question, !questionText.isEmpty {
                        Text(questionText).font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if let options = content.options {
                        ForEach(options, id: \.self) { option in
                            Button(action: { selectedQuizOption = option }) {
                                HStack {
                                    Text(option).foregroundColor(.primary)
                                    Spacer()
                                    if selectedQuizOption == option {
                                        Image(systemName: content.correctAnswer == option ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(content.correctAnswer == option ? .green : .red)
                                    } else {
                                        Image(systemName: "circle").foregroundColor(.gray)
                                    }
                                }
                                .padding().frame(maxWidth: .infinity)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding()

            default:
                Text("Unsupported: \(content.__component)").font(.caption).foregroundColor(.gray).padding()
            }

            if content.__component == "content.text", let textData = content.data, !textData.isEmpty {
                HStack {
                    Spacer()
                    Button(action: {
                        Task { @MainActor in
                            if speechManager.isSpeaking { speechManager.stop() }
                            else { speechManager.speak(textData, language: language) }
                        }
                    }) {
                        Image(systemName: speechManager.isSpeaking ? "stop.circle.fill" : "play.circle.fill")
                            .resizable().frame(width: 30, height: 30).foregroundColor(.blue)
                    }
                }
                .padding(.horizontal).padding(.top, 4)
            }
        }
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    // Helper functions for text alignment
    private func alignmentFor(_ textAlign: String?) -> HorizontalAlignment {
        switch textAlign?.lowercased() {
        case "center": return .center
        case "right": return .trailing
        default: return .leading
        }
    }

    private func textAlignmentFor(_ textAlign: String?) -> TextAlignment {
        switch textAlign?.lowercased() {
        case "center": return .center
        case "right": return .trailing
        default: return .leading
        }
    }
    
    private func frameAlignmentFor(_ textAlign: String?) -> Alignment {
        switch textAlign?.lowercased() {
        case "center": return .center
        case "right": return .trailing
        default: return .leading
        }
    }

    /// Attempts to convert a video URL to a standard YouTube embed format.
    /// If the URL is not a recognizable YouTube link, it returns the original URL.
    private func getEmbeddableVideoURL(from urlString: String, autoPlay: Bool = false) -> URL? {
        guard let initialUrl = URL(string: urlString) else {
            print("Error: Invalid initial URL string for getEmbeddableVideoURL: \(urlString)")
            return nil
        }

        var videoID: String?
        var queryItems: [URLQueryItem] = []

        // Extract query parameters if present
        if let components = URLComponents(string: urlString), let queryItemsFromUrl = components.queryItems {
            queryItems = queryItemsFromUrl
        }

        // Regex patterns for different YouTube URL formats.
        let patterns = [
            (pattern: #"youtube\.com/embed/([^?/\s]+)"#, idGroup: 1, isEmbed: true),
            (pattern: #"youtube\.com/watch\?v=([^&/\s]+)"#, idGroup: 1, isEmbed: false),
            (pattern: #"youtu\.be/([^?/\s]+)"#, idGroup: 1, isEmbed: false),
            (pattern: #"youtube\.com/shorts/([^?/\s]+)"#, idGroup: 1, isEmbed: false)
        ]

        for item in patterns {
            do {
                let regex = try NSRegularExpression(pattern: item.pattern, options: .caseInsensitive)
                let range = NSRange(urlString.startIndex..<urlString.endIndex, in: urlString)
                if let match = regex.firstMatch(in: urlString, options: [], range: range) {
                    if match.numberOfRanges > item.idGroup {
                        let idRange = match.range(at: item.idGroup)
                        if idRange.location != NSNotFound, let swiftRange = Range(idRange, in: urlString) {
                            let extractedID = String(urlString[swiftRange])
                            if !extractedID.isEmpty {
                                videoID = extractedID
                                if item.isEmbed {
                                    print("Video URL is already a YouTube embed link: \(initialUrl)")
                                    // If it's already an embed URL, add autoplay if requested
                                    if autoPlay {
                                        queryItems.append(URLQueryItem(name: "autoplay", value: "1"))
                                        var components = URLComponents(url: initialUrl, resolvingAgainstBaseURL: false)!
                                        components.queryItems = queryItems
                                        return components.url ?? initialUrl
                                    }
                                    return initialUrl
                                }
                                break
                            }
                        }
                    }
                }
            } catch {
                print("Regex error for pattern \(item.pattern): \(error)")
            }
        }
        
        guard let videoID = videoID, !videoID.isEmpty else {
            print("Warning: No valid video ID extracted from \(urlString)")
            return initialUrl
        }

        var components = URLComponents(string: "https://www.youtube.com/embed/\(videoID)")!
        if autoPlay {
            queryItems.append(URLQueryItem(name: "autoplay", value: "1"))
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        if let embedUrl = components.url {
            print("Converted video URL to YouTube embed format: \(embedUrl)")
            return embedUrl
        } else {
            print("Error: Could not create YouTube embed URL from video ID: \(videoID)")
            return initialUrl
        }
    }
}

// Parent view to manage the webView state
struct ContentParentView: View {
    @State private var webView: WKWebView? = nil

    let content: Content
    let language: String

    var body: some View {
        ContentView(content: content, language: language, webView: $webView)
    }
}

@MainActor
class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    @Published var isPaused = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, language: String) {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language.lowercased() == "es" ? "es-ES" : "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
        isSpeaking = true
        isPaused = false
    }

    func pause() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .word)
            isSpeaking = false; isPaused = true
        }
    }

    func resume() {
        if synthesizer.isPaused && isPaused {
            synthesizer.continueSpeaking()
            isSpeaking = true; isPaused = false
        }
    }

    func stop() {
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false; isPaused = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.isPaused = false
        }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        // This function must have a body, even if empty.
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        // This function must have a body, even if empty.
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.isPaused = false
        }
    }
}

// Preview Provider for ContentView
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // Ensure your actual Content and Content.Styles structs are defined and accessible
        // for these mock initializations to work. The initializers used here must match
        // the actual initializers of your structs.

        // Mock Styles (ensure Content.Styles has a matching initializer)
        let mockTextStyles = Content.Styles(
            fontSize: CGFloat(18), // Explicitly CGFloat
            fontColor: "#333333",
            isBold: true,
            isItalic: false,
            textAlign: "center"
        )

        // Mock Content items
        // Assuming 'Content' has an initializer that matches these parameters.
        // If 'viewInstanceId' is part of your Content struct and not auto-initialized, add it.
        // For example: viewInstanceId: UUID()
        let mockText = Content(
            id: 1,
            __component: "content.text",
            data: "This is preview text for a text component.",
            url: nil,
            question: nil,
            options: nil,
            correctAnswer: nil,
            styles: mockTextStyles // Use the styles object created above
        )
        
        let mockVideo = Content(
            id: 2,
            __component: "content.video",
            data: nil,
            url: "https://www.youtube.com/watch?v=wM-M-soLZKc", // Use a working video
            question: nil,
            options: nil,
            correctAnswer: nil,
            styles: nil // Styles can be nil if optional
        )
        
        let mockQuiz = Content(
            id: 3,
            __component: "content.quiz",
            data: nil,
            url: nil,
            question: "What is SwiftUI?",
            options: ["A UI Framework", "A Sandwich", "A Car Model"], // Array of strings
            correctAnswer: "A UI Framework",
            styles: nil // Styles can be nil if optional
        )

        ScrollView {
            VStack(spacing: 15) {
                ContentParentView(content: mockText, language: "en")
                ContentParentView(content: mockVideo, language: "en")
                ContentParentView(content: mockQuiz, language: "en")
            }
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}

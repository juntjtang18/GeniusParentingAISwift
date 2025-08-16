// ContentComponentView.swift

import SwiftUI
import AVKit
import WebKit
import os
import Combine

// MARK: - Refactored Sub-Views for Each Component Type

/// A view dedicated to rendering text content with a speech button.
/// It now expects to be created only with valid text data.
private struct TextView: View {
    let textData: String
    let style: CourseContentItem.Styles?
    let language: String
    
    @Environment(\.theme) var theme: Theme
    @EnvironmentObject private var speechManager: SpeechManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(textData)
                .font(.system(size: style?.fontSize ?? 17, weight: .regular))
                .italic(style?.isItalic == true)
                .foregroundColor(theme.foreground)
                .lineSpacing(5)
            
            HStack {
                Spacer()
                Button(action: {
                    Task { @MainActor in
                        if speechManager.isSpeaking { speechManager.stop() }
                        else { speechManager.speak(textData, language: language) }
                    }
                }) {
                    Image(systemName: speechManager.isSpeaking ? "stop.circle.fill" : "play.circle.fill")
                        .resizable().frame(width: 28, height: 28).foregroundColor(theme.accent)
                }
            }
        }
    }
}

/// A view for displaying an image with an optional caption.
/// It now expects to be created only with valid media data.
private struct ImageView: View {
    let media: Media
    
    @Environment(\.theme) var theme: Theme
    
    var body: some View {
        VStack(spacing: 4) {
            if let imageUrl = URL(string: media.attributes.url) {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fit).cornerRadius(10)
                    case .failure:
                        VStack {
                            Image(systemName: "photo.fill.on.rectangle.fill").font(.largeTitle)
                            Text("Image failed to load").font(.caption)
                        }.foregroundColor(.gray)
                    default:
                        ProgressView()
                    }
                }
                .frame(minHeight: 200)
                
                if let caption = media.attributes.caption, !caption.isEmpty {
                    Text(caption).font(.caption).foregroundColor(theme.secondary).italic().padding(.top, 2)
                }
            } else {
                Text("Invalid Image URL").foregroundColor(.red)
            }
        }
    }
}

/// A view for playing an uploaded video file with a caption.
/// It now expects to be created only with valid media data.
private struct VideoView: View {
    let media: Media
    
    @Environment(\.theme) var theme: Theme
    @State private var player: AVPlayer?
    @State private var isPlaying = false

    /// A computed property that safely creates and type-erases the publisher for the player's rate.
    private var ratePublisher: AnyPublisher<Float, Never> {
        player?
            .publisher(for: \.rate)
            .eraseToAnyPublisher()
        ?? Empty<Float, Never>()
            .eraseToAnyPublisher()
    }

    var body: some View {
        VStack(spacing: 4) {
            if let videoURL = URL(string: media.attributes.url) {
                ZStack {
                    VideoPlayer(player: player)
                        .onAppear {
                            if player == nil {
                                player = AVPlayer(url: videoURL)
                            }
                        }
                        .onDisappear {
                            player?.pause()
                        }
                    
                    if !isPlaying {
                        Button(action: {
                            player?.play()
                        }) {
                            Image(systemName: "play.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .frame(minHeight: 200, idealHeight: 250, maxHeight: 300)
                .cornerRadius(10)
                .onReceive(ratePublisher) { rate in
                    isPlaying = rate != 0
                }

                if let caption = media.attributes.caption, !caption.isEmpty {
                    Text(caption).font(.caption).foregroundColor(theme.secondary).italic().padding(.top, 2)
                }
            } else {
                Text("Invalid Video URL").foregroundColor(.red)
            }
        }
    }
}

/// A view for displaying an embedded external video (e.g., YouTube).
private struct ExternalVideoView: View {
    let item: CourseContentItem
    
    @Environment(\.theme) var theme: Theme
    @State private var webView: WKWebView? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let thumbnailUrl = URL(string: item.thumbnail?.data?.attributes.url ?? "") {
                AsyncImage(url: thumbnailUrl) { $0.resizable().aspectRatio(contentMode: .fit).cornerRadius(8) }
                    placeholder: { ProgressView() }
                    .frame(maxWidth: .infinity, idealHeight: 180)
            }
            
            if let urlString = item.external_url, !urlString.isEmpty, let embedUrl = getEmbeddableVideoURL(from: urlString) {
                VideoPlayerWebView(urlString: embedUrl.absoluteString, webView: $webView)
                    .frame(minHeight: 200, idealHeight: 250, maxHeight: 300)
                    .cornerRadius(10)
            } else {
                Text("Video could not be loaded.").foregroundColor(.red)
            }

            if let caption = item.caption, !caption.isEmpty {
                Text(caption).font(.caption).foregroundColor(theme.secondary).italic().frame(maxWidth: .infinity, alignment: .center).padding(.top, 2)
            }
        }
    }
    
    // --- FIXED: Restored the robust regex-based URL parser ---
    private func getEmbeddableVideoURL(from urlString: String) -> URL? {
        let patterns = [
            #"v=([a-zA-Z0-9_-]{11})"#,
            #"youtu\.be/([a-zA-Z0-9_-]{11})"#,
            #"embed/([a-zA-Z0-9_-]{11})"#,
            #"shorts/([a-zA-Z0-9_-]{11})"#,
            #"googleusercontent.com/youtube.com/([0-9])"#
        ]

        var videoID: String?
        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern)
                let range = NSRange(urlString.startIndex..., in: urlString)
                if let match = regex.firstMatch(in: urlString, options: [], range: range) {
                    if match.numberOfRanges > 1, let idRange = Range(match.range(at: 1), in: urlString) {
                        videoID = String(urlString[idRange])
                        break
                    }
                }
            } catch {
                // Log errors if necessary, but continue trying other patterns
                continue
            }
        }
        
        guard let finalVideoID = videoID else { return nil }

        return URL(string: "https://www.youtube-nocookie.com/embed/\(finalVideoID)?playsinline=1&controls=1&modestbranding=1&fs=0&rel=0")
    }
}

/// A complete view for handling a quiz component, including its state.
private struct QuizView: View {
    let item: CourseContentItem
    
    @Environment(\.theme) var theme: Theme
    @State private var selectedOption: String?
    @State private var isSubmitted = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let question = item.question, !question.isEmpty {
                Text(question).font(.headline).padding(.bottom, 5)
            }
            
            if let options = item.options?.value {
                ForEach(options, id: \.self) { option in
                    QuizOptionView(
                        optionText: option,
                        isSelected: selectedOption == option,
                        isCorrect: item.correctAnswer == option,
                        isSubmitted: isSubmitted
                    ) {
                        selectedOption = option
                        isSubmitted = true
                    }
                }
            }
            
            if isSubmitted, selectedOption != item.correctAnswer {
                HStack(alignment: .top) {
                    Image(systemName: "info.circle.fill").foregroundColor(.blue)
                    Text("The correct answer is: **\(item.correctAnswer ?? "N/A")**").font(.footnote)
                }
                .padding(.top, 10)
                .transition(.opacity.animation(.easeInOut))
            }
        }.padding()
    }
}

/// A helper view for a single quiz option button.
private struct QuizOptionView: View {
    let optionText: String
    let isSelected: Bool
    let isCorrect: Bool
    let isSubmitted: Bool
    let action: () -> Void
    
    @Environment(\.theme) var theme: Theme

    var body: some View {
        Button(action: action) {
            HStack {
                Text(optionText)
                Spacer()
                if isSubmitted {
                    if isCorrect {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    } else if isSelected {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                    }
                }
            }
            .font(.headline)
            .foregroundColor(theme.foreground)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8).stroke(isSelected ? theme.accent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isSubmitted)
    }
}


// MARK: - Main Content Component View (Dispatcher)
struct ContentComponentView: View {
    let contentItem: CourseContentItem
    let language: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch contentItem.__component {
            case "coursecontent.text":
                if let textData = contentItem.data, !textData.isEmpty {
                    TextView(textData: textData, style: contentItem.style, language: language)
                }

            case "coursecontent.image":
                if let media = contentItem.image_file?.data {
                    ImageView(media: media)
                }

            case "coursecontent.video":
                if let media = contentItem.video_file?.data {
                    VideoView(media: media)
                }

            case "coursecontent.external-video":
                ExternalVideoView(item: contentItem)

            case "coursecontent.quiz":
                QuizView(item: contentItem)

            case "coursecontent.pagebreaker":
                EmptyView()

            default:
                Text("Unsupported component: \(contentItem.__component)")
                    .font(.caption).foregroundColor(.gray).padding()
            }
        }
        .padding(.vertical, 8)
    }
}

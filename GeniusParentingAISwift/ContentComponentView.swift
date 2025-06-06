import SwiftUI
import AVKit  // For VideoPlayer
import WebKit // For VideoPlayerWebView

// MARK: - Content Component View

struct ContentComponentView: View {
    let contentItem: Content
    let language: String // For speech synthesis, if components have translatable text
    @StateObject private var speechManager = SpeechManager()

    // State variables for quiz interactivity, scoped to this component instance
    @State private var selectedOption: String? = nil
    @State private var isAnswerSubmitted = false
    
    // State for WKWebView, specific to each instance of VideoPlayerWebView if used
    @State private var webViewForExternalVideo: WKWebView? = nil

    var body: some View {
        // This print statement helps debug what the view is receiving.
        let _ = print("\n--- Rendering Component: \(contentItem.__component) (ID: \(contentItem.id ?? -1)) ---")
        
        VStack(alignment: alignmentFor(contentItem.style?.textAlign), spacing: 10) {
            // The cases now match the component names from your Strapi backend
            switch contentItem.__component {
            case "coursecontent.text":
                let _ = print("""
                    - Type: Text
                    - Data: '\(contentItem.data ?? "nil")'
                """)
                if let textData = contentItem.data, !textData.isEmpty {
                    Text(textData)
                        .font(.system(size: contentItem.style?.fontSize ?? 17,
                                      weight: contentItem.style?.isBold == true ? .bold : .regular))
                        .italic(contentItem.style?.isItalic == true)
                        .foregroundColor(Color(hex: contentItem.style?.fontColor ?? "#333333"))
                        .lineSpacing(5)
                        .multilineTextAlignment(textAlignmentFor(contentItem.style?.textAlign))
                        .frame(maxWidth: .infinity, alignment: frameAlignmentFor(contentItem.style?.textAlign))
                    HStack {
                        Spacer()
                        Button(action: {
                            Task { @MainActor in
                                if speechManager.isSpeaking { speechManager.stop() }
                                else { speechManager.speak(textData, language: language) }
                            }
                        }) {
                            Image(systemName: speechManager.isSpeaking ? "stop.circle.fill" : "play.circle.fill")
                                .resizable().frame(width: 28, height: 28).foregroundColor(.accentColor)
                        }
                    }.padding(.top, 2)
                }

            case "coursecontent.image":
                let _ = print("""
                    - Type: Image
                    - Media Object: \(contentItem.imageFile != nil ? "Present" : "nil")
                    - URL: \(contentItem.imageFile?.data?.attributes.url ?? "nil")
                """)
                if let media = contentItem.imageFile?.data {
                    if let imageUrl = URL(string: media.attributes.url) {
                        AsyncImage(url: imageUrl) { phase in
                            switch phase {
                            case .empty: ProgressView().frame(minHeight: 200, idealHeight: 250).frame(maxWidth: .infinity)
                            case .success(let image): image.resizable().aspectRatio(contentMode: .fit).cornerRadius(10)
                            case .failure: VStack { Image(systemName: "photo.fill.on.rectangle.fill").font(.largeTitle).foregroundColor(.gray); Text("Image failed to load").font(.caption).foregroundColor(.red) }.frame(minHeight:150).frame(maxWidth: .infinity)
                            @unknown default: EmptyView()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        if let caption = media.attributes.caption, !caption.isEmpty {
                            Text(caption).font(.caption).foregroundColor(.secondary).italic().frame(maxWidth: .infinity, alignment: .center).padding(.top, 2)
                        }
                    } else { Text("Image URL is invalid.").foregroundColor(.red).padding() }
                } else { Text("Image not available.").foregroundColor(.red).padding() }

            case "coursecontent.video": // Uploaded Video
                let _ = print("""
                    - Type: Uploaded Video
                    - Media Object: \(contentItem.videoFile != nil ? "Present" : "nil")
                    - URL: \(contentItem.videoFile?.data?.attributes.url ?? "nil")
                """)
                if let media = contentItem.videoFile?.data {
                   if let videoURL = URL(string: media.attributes.url) {
                        VideoPlayer(player: AVPlayer(url: videoURL))
                            .frame(minHeight: 200, idealHeight: 250, maxHeight: 300)
                            .cornerRadius(10)
                        if let caption = media.attributes.caption, !caption.isEmpty {
                            Text(caption).font(.caption).foregroundColor(.secondary).italic().frame(maxWidth: .infinity, alignment: .center).padding(.top, 2)
                        }
                   } else { Text("Uploaded video URL is invalid.").foregroundColor(.red).padding() }
                } else { Text("Uploaded video not available.").foregroundColor(.red).padding() }

            case "coursecontent.external-video":
                 let _ = print("""
                    - Type: External Video
                    - URL: \(contentItem.externalUrl ?? "nil")
                    - Thumbnail: \(contentItem.thumbnail?.data?.attributes.url ?? "nil")
                 """)
                VStack(alignment: .leading, spacing: 5) {
                    if let thumbnailMedia = contentItem.thumbnail?.data {
                       if let thumbnailUrl = URL(string: thumbnailMedia.attributes.url) {
                            AsyncImage(url: thumbnailUrl) { phase in
                                 switch phase {
                                 case .empty: ProgressView().frame(height: 180).frame(maxWidth: .infinity)
                                 case .success(let image): image.resizable().aspectRatio(contentMode: .fit).cornerRadius(8)
                                 case .failure: Image(systemName: "video.badge.exclamationmark").font(.largeTitle).foregroundColor(.gray).frame(height:180).frame(maxWidth: .infinity)
                                 @unknown default: EmptyView()
                                 }
                            }
                            .frame(maxWidth: .infinity, idealHeight: 180)
                       } else { Text("Thumbnail URL is invalid.").foregroundColor(.red).padding(.bottom, 5) }
                    }

                    if let externalVideoUrlString = contentItem.externalUrl, !externalVideoUrlString.isEmpty {
                        let finalVideoUrl = getEmbeddableVideoURL(from: externalVideoUrlString)

                        if let urlToPlay = finalVideoUrl, urlToPlay.absoluteString.contains("youtube.com/embed") {
                            VideoPlayerWebView(urlString: urlToPlay.absoluteString, webView: $webViewForExternalVideo)
                                .frame(minHeight: 200, idealHeight: 250, maxHeight: 300)
                                .cornerRadius(10)
                        } else if let directUrl = URL(string: externalVideoUrlString) {
                            Link("Watch Video: \(externalVideoUrlString.prefix(50))...", destination: directUrl)
                                .font(.callout).padding(.top, 5)
                        } else {
                            Text("External video URL is invalid.").foregroundColor(.red)
                        }
                    } else { Text("External video URL missing.").foregroundColor(.red) }

                    if let caption = contentItem.caption, !caption.isEmpty {
                        Text(caption).font(.caption).foregroundColor(.secondary).italic().frame(maxWidth: .infinity, alignment: .center).padding(.top, 2)
                    }
                }

            case "coursecontent.quiz":
                let _ = print("    - Question: \(contentItem.question ?? "nil")")
                VStack(alignment: .leading, spacing: 12) {
                    if let questionText = contentItem.question, !questionText.isEmpty {
                        Text(questionText).font(.headline).padding(.bottom, 5)
                    }
                    if let optionsArray = contentItem.options {
                        ForEach(optionsArray, id: \.self) { optionText in
                            Button(action: {
                                if !isAnswerSubmitted { // Allow selection only once
                                    selectedOption = optionText
                                    isAnswerSubmitted = true
                                }
                            }) {
                                HStack {
                                    Text(optionText).foregroundColor(Color(UIColor.label))
                                    Spacer()
                                    
                                    // Logic for visual feedback
                                    if isAnswerSubmitted {
                                        if optionText == contentItem.correctAnswer {
                                            // Always show the green check on the correct answer once submitted
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.headline)
                                        } else if optionText == selectedOption {
                                            // Show a red cross on the user's incorrect selection
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.headline)
                                        }
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                                .overlay(
                                    // Add a border to indicate selection
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedOption == optionText ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(isAnswerSubmitted) // Disable button after submission
                        }
                    }
                    
                    // Show the correct answer explanation if a wrong answer was selected
                    if isAnswerSubmitted, let selected = selectedOption, selected != contentItem.correctAnswer {
                        HStack(alignment: .top) {
                            Image(systemName: "info.circle.fill").foregroundColor(.blue)
                            Text("The correct answer is: **\(contentItem.correctAnswer ?? "N/A")**")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 10)
                        .transition(.opacity.animation(.easeInOut))
                    }
                }.padding()

            case "coursecontent.pagebreaker":
                let _ = print("""
                    - Type: Page Breaker
                    - Back Button: \(String(describing: contentItem.backbutton))
                    - Next Button: \(String(describing: contentItem.nextbutton))
                """)
                EmptyView()

            default:
                let _ = print("!!! Encountered an unsupported component type. !!!")
                Text("Unsupported component: \(contentItem.__component)")
                    .font(.caption).foregroundColor(.gray).padding()
            }
        }
        .padding(.vertical, 8)
    }

    // Helper functions
    private func alignmentFor(_ textAlign: String?) -> HorizontalAlignment {
        switch textAlign?.lowercased() { case "center": .center; case "right": .trailing; default: .leading }
    }
    private func textAlignmentFor(_ textAlign: String?) -> TextAlignment {
        switch textAlign?.lowercased() { case "center": .center; case "right": .trailing; default: .leading }
    }
    private func frameAlignmentFor(_ textAlign: String?) -> Alignment {
        switch textAlign?.lowercased() { case "center": .center; case "right": .trailing; default: .leading }
    }
    private func getEmbeddableVideoURL(from urlString: String, autoPlay: Bool = false) -> URL? {
        // ... (implementation is unchanged)
        guard URL(string: urlString) != nil else { return nil }
        var videoID: String?; let patterns = [(pattern:#"youtube\.com/embed/([^?/\s]+)"#,idGroup:1,isEmbed:true),(pattern:#"youtube\.com/watch\?v=([^&/\s]+)"#,idGroup:1,isEmbed:false),(pattern:#"youtu\.be/([^?/\s]+)"#,idGroup:1,isEmbed:false),(pattern:#"youtube\.com/shorts/([^?/\s]+)"#,idGroup:1,isEmbed:false)]; for item in patterns { do { let regex = try NSRegularExpression(pattern: item.pattern, options: .caseInsensitive); let nsRange = NSRange(urlString.startIndex..<urlString.endIndex, in: urlString); if let match = regex.firstMatch(in: urlString, options: [], range: nsRange) { if match.numberOfRanges > item.idGroup { let idNSRange = match.range(at: item.idGroup); if idNSRange.location != NSNotFound, let swiftRange = Range(idNSRange, in: urlString) { let extractedID = String(urlString[swiftRange]); if !extractedID.isEmpty { videoID = extractedID; if item.isEmbed { var components = URLComponents(string: urlString)!; var queryItems = components.queryItems ?? []; let requiredParams: [String: String] = ["playsinline":"1","modestbranding":"1","controls":"1","fs":"0","rel":"0"]; requiredParams.forEach { key, value in if !queryItems.contains(where: { $0.name == key }) { queryItems.append(URLQueryItem(name: key, value: value)) } }; if autoPlay && !queryItems.contains(where: { $0.name == "autoplay" }) { queryItems.append(URLQueryItem(name: "autoplay", value: "1")) }; components.queryItems = queryItems.isEmpty ? nil : queryItems.filter { $0.value != nil }; return components.url }; break } } } } } catch { print("Regex error: \(error)") } }; guard let finalVideoID = videoID, !finalVideoID.isEmpty else { return URL(string: urlString) }; var components = URLComponents(string: "https://www.youtube.com/embed/\(finalVideoID)")!; var queryItems: [URLQueryItem] = [URLQueryItem(name: "playsinline", value: "1"), URLQueryItem(name: "modestbranding", value: "1"), URLQueryItem(name: "controls", value: "1"), URLQueryItem(name: "fs", value: "0"), URLQueryItem(name: "rel", value: "0")]; if autoPlay { queryItems.append(URLQueryItem(name: "autoplay", value: "1")) }; components.queryItems = queryItems.isEmpty ? nil : queryItems; return components.url
    }
}

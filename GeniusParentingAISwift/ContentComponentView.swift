// ContentComponentView.swift

import SwiftUI
import AVKit
import WebKit

// MARK: - Content Component View

struct ContentComponentView: View {
    let contentItem: Content
    let language: String
    
    // FIXED: Access the shared SpeechManager from the environment to fix performance warnings.
    @EnvironmentObject private var speechManager: SpeechManager
    
    @State private var selectedOption: String? = nil
    @State private var isAnswerSubmitted = false
    @State private var webViewForExternalVideo: WKWebView? = nil

    var body: some View {
        VStack(alignment: alignmentFor(contentItem.style?.textAlign), spacing: 10) {
            switch contentItem.__component {
            case "coursecontent.text":
                if let textData = contentItem.data, !textData.isEmpty {
                    Text(textData)
                        .font(.system(size: contentItem.style?.fontSize ?? 17,
                                      weight: .regular))
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

            case "coursecontent.video":
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
                        if let embedUrl = getEmbeddableVideoURL(from: externalVideoUrlString, autoPlay: false) {
                            VideoPlayerWebView(urlString: embedUrl.absoluteString, webView: $webViewForExternalVideo)
                                .frame(minHeight: 200, idealHeight: 250, maxHeight: 300)
                                .cornerRadius(10)
                        } else if let directVideoUrl = URL(string: externalVideoUrlString), ["mp4", "mov", "m4v"].contains(directVideoUrl.pathExtension.lowercased()) {
                            VideoPlayer(player: AVPlayer(url: directVideoUrl))
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
                VStack(alignment: .leading, spacing: 12) {
                    if let questionText = contentItem.question, !questionText.isEmpty {
                        Text(questionText).font(.headline).padding(.bottom, 5)
                    }
                    if let optionsArray = contentItem.options?.value {
                        ForEach(optionsArray, id: \.self) { optionText in
                            Button(action: {
                                if !isAnswerSubmitted {
                                    selectedOption = optionText
                                    isAnswerSubmitted = true
                                 }
                            }) {
                                HStack {
                                    Text(optionText).foregroundColor(Color(UIColor.label))
                                    Spacer()
                                    
                                    if isAnswerSubmitted {
                                        if optionText == contentItem.correctAnswer {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.headline)
                                        } else if optionText == selectedOption {
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
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedOption == optionText ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(isAnswerSubmitted)
                        }
                    }
                    
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
                EmptyView()

            default:
                Text("Unsupported component: \(contentItem.__component)")
                    .font(.caption).foregroundColor(.gray).padding()
            }
        }
        .padding(.vertical, 8)
    }

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
        let patterns = [
            #"v=([a-zA-Z0-9_-]{11})"#,
            #"youtu\.be/([a-zA-Z0-9_-]{11})"#,
            #"embed/([a-zA-Z0-9_-]{11})"#,
            #"shorts/([a-zA-Z0-9_-]{11})"#
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
                print("Regex error: \(error.localizedDescription)")
                continue
            }
        }

        guard let finalVideoID = videoID else {
            return nil
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.youtube-nocookie.com"
        components.path = "/embed/\(finalVideoID)"
        
        var queryItems = [
            URLQueryItem(name: "playsinline", value: "1"),
            URLQueryItem(name: "controls", value: "1"),
            URLQueryItem(name: "modestbranding", value: "1"),
            URLQueryItem(name: "fs", value: "0"),
            URLQueryItem(name: "rel", value: "0")
        ]
        
        if autoPlay {
            queryItems.append(URLQueryItem(name: "autoplay", value: "1"))
        }
        
        components.queryItems = queryItems
        
        return components.url
    }
}

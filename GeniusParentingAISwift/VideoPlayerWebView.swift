// VideoPlayerWebView.swift

import SwiftUI
import WebKit // Required for WKWebView

/// A SwiftUI view that wraps a WKWebView to display web content, typically used for video embeds.
struct VideoPlayerWebView: UIViewRepresentable {
    let urlString: String
    @Binding var webView: WKWebView? // Use binding to allow parent to hold a reference if needed

    /// Creates the WKWebView and configures it.
    func makeUIView(context: Context) -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []

        if #available(iOS 14.0, *) {
            webConfiguration.defaultWebpagePreferences.allowsContentJavaScript = true
        } else {
            webConfiguration.preferences.javaScriptEnabled = true
        }

        let newWebView = WKWebView(frame: .zero, configuration: webConfiguration)
        newWebView.scrollView.isScrollEnabled = false
        newWebView.navigationDelegate = context.coordinator
        newWebView.uiDelegate = context.coordinator
        
        DispatchQueue.main.async {
            self.webView = newWebView
        }
        
        return newWebView
    }

    /// Updates the WKWebView when the urlString changes or for initial load.
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = URL(string: urlString) else {
            loadErrorPage(on: uiView, message: "Invalid video URL provided.")
            print("Error: Invalid URL string for VideoPlayerWebView: \(urlString)")
            return
        }
        
        let currentMainFrameURL = uiView.url?.absoluteString.split(separator: "?").first.map(String.init)
        let newMainFrameURL = url.absoluteString.split(separator: "?").first.map(String.init)

        if currentMainFrameURL != newMainFrameURL || uiView.url == nil {
            // REVISED: Removed the flawed if/else logic. We now always load via an iframe
            // because this view will only be used for proper embed URLs.
            let html = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0, shrink-to-fit=no, user-scalable=no">
                <style>
                    body, html { margin: 0; padding: 0; height: 100%; overflow: hidden; background-color: #000; }
                    iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0; }
                </style>
            </head>
            <body>
                <iframe src="\(url.absoluteString)"
                        title="YouTube video player"
                        frameborder="0"
                        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                        allowfullscreen></iframe>
            </body>
            </html>
            """
            // Use the video's domain as the base URL for proper context
            uiView.loadHTMLString(html, baseURL: URL(string: "\(url.scheme ?? "https")://\(url.host ?? "youtube.com")"))
            print("VideoPlayerWebView: Loading video iframe with URL - \(url.absoluteString)")
        }
    }
    
    private func loadErrorPage(on webView: WKWebView, message: String) {
        let htmlError = """
        <html><body style="display:flex;justify-content:center;align-items:center;height:100%;margin:0;background-color:#f0f0f0;color:#333;font-family:sans-serif;">
        <p>\(message)</p></body></html>
        """
        webView.loadHTMLString(htmlError, baseURL: nil)
    }

    /// Creates a Coordinator for handling WKNavigationDelegate and WKUIDelegate methods.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.stopLoading()
        uiView.navigationDelegate = nil
        uiView.uiDelegate = nil
        print("VideoPlayerWebView dismantled for URL: \(uiView.url?.absoluteString ?? "unknown")")
    }


    /// Coordinator class to act as a delegate for WKWebView.
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: VideoPlayerWebView

        init(_ parent: VideoPlayerWebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("VideoPlayerWebView Coordinator: Finished loading for URL: \(webView.url?.absoluteString ?? "unknown")")
            
            // REVISED: Removed the flawed check. This command is for the YouTube Iframe API,
            // so we attempt it if autoplay is requested.
            if parent.urlString.contains("autoplay=1") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    let script = "document.getElementsByTagName('iframe')[0].contentWindow.postMessage('{\"event\":\"command\",\"func\":\"playVideo\",\"args\":\"\"}','*');"
                    webView.evaluateJavaScript(script) { result, error in
                        if let error = error {
                            print("VideoPlayerWebView: JS playVideo command error: \(error.localizedDescription)")
                        } else {
                            print("VideoPlayerWebView: JS playVideo command sent. Result: \(String(describing: result))")
                        }
                    }
                }
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("VideoPlayerWebView Coordinator: Failed navigation with error: \(error.localizedDescription)")
            parent.loadErrorPage(on: webView, message: "Could not load video. Error: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("VideoPlayerWebView Coordinator: Failed provisional navigation with error: \(error.localizedDescription)")
            parent.loadErrorPage(on: webView, message: "Could not load video content. Error: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
            return nil
        }
    }
}

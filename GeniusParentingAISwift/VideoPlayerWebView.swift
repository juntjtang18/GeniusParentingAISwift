import SwiftUI
import WebKit // Required for WKWebView

/// A SwiftUI view that wraps a WKWebView to display web content, typically used for video embeds.
struct VideoPlayerWebView: UIViewRepresentable {
    let urlString: String
    @Binding var webView: WKWebView? // Use binding to allow parent to hold a reference if needed

    /// Creates the WKWebView and configures it.
    func makeUIView(context: Context) -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        // Allows videos to play inline by default on iPhone, rather than fullscreen.
        webConfiguration.allowsInlineMediaPlayback = true
        // Allow autoplay for videos, though user interaction might still be required by the browser/OS policies
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []


        // For YouTube and many modern web pages, enabling JavaScript is essential.
        if #available(iOS 14.0, *) {
            webConfiguration.defaultWebpagePreferences.allowsContentJavaScript = true
        } else {
            webConfiguration.preferences.javaScriptEnabled = true
        }

        let newWebView = WKWebView(frame: .zero, configuration: webConfiguration)
        newWebView.scrollView.isScrollEnabled = false // Disable scrolling within the webview itself
        newWebView.navigationDelegate = context.coordinator // For handling navigation events
        newWebView.uiDelegate = context.coordinator // For handling UI-related events like new windows
        
        DispatchQueue.main.async { // Ensure this update happens on the main thread
            self.webView = newWebView // Set the binding
        }
        
        // Initial load is handled in updateUIView or here if urlString is guaranteed at init
        // For robustness, handle initial load and updates in updateUIView primarily.
        // However, to ensure content is loaded on first make, we can do an initial load here if appropriate.
        // It's often better to let updateUIView handle the first load too.
        // But if updateUIView isn't called immediately or reliably on first appearance for some reason:
        // if let url = URL(string: urlString) {
        // newWebView.load(URLRequest(url: url)) // Or loadHTMLString for iframe
        // }
        return newWebView
    }

    /// Updates the WKWebView when the urlString changes or for initial load.
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = URL(string: urlString) else {
            loadErrorPage(on: uiView, message: "Invalid video URL provided.")
            print("Error: Invalid URL string for VideoPlayerWebView: \(urlString)")
            return
        }
        
        // Check if the webView is already displaying this URL or a derivative (like an error page)
        // to prevent unnecessary reloads if the content is already correct.
        let currentMainFrameURL = uiView.url?.absoluteString.split(separator: "?").first.map(String.init)
        let newMainFrameURL = url.absoluteString.split(separator: "?").first.map(String.init)

        if currentMainFrameURL != newMainFrameURL || uiView.url == nil || (uiView.url?.absoluteString.hasPrefix("data:text/html") ?? false) {
            if urlString.contains("youtube.com/embed") {
                // Construct HTML to embed the YouTube video properly with an iframe
                // This allows better control over iframe parameters like playsinline, controls, etc.
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
                uiView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com")) // Base URL for YouTube context
                print("VideoPlayerWebView: Loading YouTube iframe with URL - \(url.absoluteString)")
            } else {
                // For other URLs, attempt a direct load.
                // Consider if this is for direct video files (where native VideoPlayer might be better)
                // or other embeddable web content.
                uiView.load(URLRequest(url: url))
                print("VideoPlayerWebView: Loading direct URL - \(url.absoluteString)")
            }
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
        // Remove all KVO observers, or other cleanup if necessary.
        print("VideoPlayerWebView dismantled for URL: \(uiView.url?.absoluteString ?? "unknown")")
    }


    /// Coordinator class to act as a delegate for WKWebView.
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: VideoPlayerWebView

        init(_ parent: VideoPlayerWebView) {
            self.parent = parent
        }

        // Called when navigation finishes.
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("VideoPlayerWebView Coordinator: Finished loading for URL: \(webView.url?.absoluteString ?? "unknown")")
            // Attempt to autoplay YouTube videos (might be blocked by browser/OS policies)
            if parent.urlString.contains("youtube.com/embed") && parent.urlString.contains("autoplay=1") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { // Increased delay slightly
                    // This JavaScript targets YouTube's IFrame Player API
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

        // Called when navigation fails.
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("VideoPlayerWebView Coordinator: Failed navigation with error: \(error.localizedDescription)")
            parent.loadErrorPage(on: webView, message: "Could not load video. Error: \(error.localizedDescription)")
        }
        
        // Called when provisional navigation fails (e.g., server cannot be reached).
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("VideoPlayerWebView Coordinator: Failed provisional navigation with error: \(error.localizedDescription)")
            parent.loadErrorPage(on: webView, message: "Could not load video content. Error: \(error.localizedDescription)")
        }

        // Handle requests to open new windows (e.g., target="_blank" links from within the iframe)
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // If the navigation action is for a new window (targetFrame is nil),
            // open the URL in the system browser (Safari).
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
            return nil // Do not create a new WKWebView within the app for these actions.
        }
    }
}

// Preview Provider for VideoPlayerWebView (optional, for development)
struct VideoPlayerWebView_Previews: PreviewProvider {
    static var previews: some View {
        // Example YouTube embed URL with autoplay and other params
        let embedUrl = "https://www.youtube.com/embed/wM-M-soLZKc?playsinline=1&modestbranding=1&controls=1&fs=0&rel=0"
        VideoPlayerWebView(urlString: embedUrl, webView: .constant(nil))
            .frame(height: 250)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}

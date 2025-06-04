import SwiftUI
import WebKit // Required for WKWebView

/// A SwiftUI view that wraps a WKWebView to display web content, typically used for video embeds.
struct VideoPlayerWebView: UIViewRepresentable {
    let urlString: String
    @Binding var webView: WKWebView? // Use binding to set the webView instance

    /// Creates the WKWebView and configures it.
    func makeUIView(context: Context) -> WKWebView {
        // Configure web view preferences
        let webConfiguration = WKWebViewConfiguration()
        // Allows videos to play inline by default on iPhone, rather than fullscreen.
        // On iPad, videos play inline by default.
        webConfiguration.allowsInlineMediaPlayback = true
        
        // For YouTube and many modern web pages, enabling JavaScript is essential.
        // Use defaultWebpagePreferences for iOS 14+
        if #available(iOS 14.0, *) {
            webConfiguration.defaultWebpagePreferences.allowsContentJavaScript = true
        } else {
            // Fallback for older iOS versions if necessary, though your target is likely iOS 14+
            webConfiguration.preferences.javaScriptEnabled = true
        }

        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.scrollView.isScrollEnabled = false // Disable scrolling within the webview itself
        webView.navigationDelegate = context.coordinator // For handling navigation events
        webView.uiDelegate = context.coordinator // For handling UI-related events
        self.webView = webView // Set the binding
        return webView
    }

    /// Updates the WKWebView when the urlString changes.
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = URL(string: urlString) else {
            // Load a simple HTML error message if the URL is invalid
            let htmlError = """
            <html>
            <body style="display:flex; justify-content:center; align-items:center; height:100%; margin:0; background-color:#f0f0f0; color:#333; font-family:sans-serif;">
                <p>Invalid video URL.</p>
            </body>
            </html>
            """
            uiView.loadHTMLString(htmlError, baseURL: nil)
            print("Error: Invalid URL string for VideoPlayerWebView: \(urlString)")
            return
        }
        
        // Load as an iframe for YouTube embeds
        let html = """
        <html><body style="margin:0;padding:0;"><iframe width="100%" height="100%" src="\(url.absoluteString)" title="YouTube Video" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe></body></html>
        """
        uiView.loadHTMLString(html, baseURL: nil)
        print("VideoPlayerWebView: Loading iframe with URL - \(url.absoluteString)")
    }

    /// Creates a Coordinator for handling WKNavigationDelegate and WKUIDelegate methods.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    /// Coordinator class to act as a delegate for WKWebView.
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: VideoPlayerWebView

        init(_ parent: VideoPlayerWebView) {
            self.parent = parent
        }

        // Called when navigation finishes.
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("VideoPlayerWebView: Finished loading content for URL: \(webView.url?.absoluteString ?? "unknown")")
        }

        // Called when navigation fails.
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("VideoPlayerWebView: Failed to load content with error: \(error.localizedDescription)")
            let htmlError = """
            <html><body style="display:flex;justify-content:center;align-items:center;height:100%;margin:0;background-color:#f0f0f0;color:#cc0000;font-family:sans-serif;">
            <p>Could not load video. Error: \(error.localizedDescription)</p></body></html>
            """
            webView.loadHTMLString(htmlError, baseURL: nil)
        }
        
        // Called when provisional navigation fails.
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("VideoPlayerWebView: Failed provisional navigation with error: \(error.localizedDescription)")
            let htmlError = """
            <html><body style="display:flex;justify-content:center;align-items:center;height:100%;margin:0;background-color:#f0f0f0;color:#cc0000;font-family:sans-serif;">
            <p>Could not load video. Error: \(error.localizedDescription)</p></body></html>
            """
            webView.loadHTMLString(htmlError, baseURL: nil)
        }

        // Handle requests to open new windows (e.g., target="_blank")
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                if let url = navigationAction.request.url {
                    UIApplication.shared.open(url)
                }
            }
            return nil
        }
    }
}

// Preview Provider for VideoPlayerWebView (optional, for development)
struct VideoPlayerWebView_Previews: PreviewProvider {
    static var previews: some View {
        // Example YouTube embed URL
        VideoPlayerWebView(urlString: "https://www.youtube.com/embed/wM-M-soLZKc", webView: .constant(nil))
            .frame(height: 250)
            .padding()
    }
}

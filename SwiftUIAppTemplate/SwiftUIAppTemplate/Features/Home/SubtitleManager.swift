import Foundation
import WebKit

class SubtitleManager {
    static let shared = SubtitleManager()
    
    private init() {}
    
    /// جلب ملف الترجمة بالخلفية بشكل صامت
    func fetchArabicSubtitleURL(for tmdbID: Int, isMovie: Bool) async -> String? {
        let type = isMovie ? "movie" : "tv"
        let subtitleEndpoint = "https://sub.vidsrc.stream/sub/\(type)/\(tmdbID)/ar.vtt"
        
        guard let url = URL(string: subtitleEndpoint) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 2
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                return subtitleEndpoint
            }
        } catch {}
        
        return nil
    }
    
    /// حقن الترجمة بداخل المشغل إذا توفرت
    func injectSubtitleScript(into webView: WKWebView, subtitleURL: String) {
        let jsScript = """
        var video = document.querySelector('video');
        if (video) {
            var track = document.createElement('track');
            track.kind = 'subtitles';
            track.label = 'العربية';
            track.srclang = 'ar';
            track.src = '\(subtitleURL)';
            track.default = true;
            video.appendChild(track);
        }
        """
        webView.evaluateJavaScript(jsScript, completionHandler: nil)
    }
}



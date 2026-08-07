import Foundation

class MediaScraperManager {
    static let shared = MediaScraperManager()
    
    // يوزر ايجنت الآيباد لتجاوز حظر الشاشة البيضاء
    private let userAgent = "Mozilla/5.0 (iPad; CPU OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1"
    
    /// توليد روابط السيرفرين (الأساسي والاحتياطي) باستخدام الروابط الجاية من الفايربيس
    func getServerURLs(tmdbID: Int, imdbID: String?, isMovie: Bool, season: Int = 1, episode: Int = 1) -> [String] {
        let idParam = (imdbID != nil && !imdbID!.isEmpty) ? imdbID! : "\(tmdbID)"
        
        // سحب الروابط مباشرة من ملف AppConfig
        let server1 = AppConfig.shared.server1
        let server2 = AppConfig.shared.server2
        
        if isMovie {
            return [
                "\(server1)/embed/movie/\(idParam)",
                "\(server2)/movie/\(idParam)"
            ]
        } else {
            return [
                "\(server1)/embed/tv/\(idParam)/\(season)/\(episode)",
                "\(server2)/tv/\(idParam)/\(season)/\(episode)"
            ]
        }
    }
    
    /// دالة الفحص الشاملة قبل عرض البوستر
    func isAvailableOnAnyServer(tmdbID: Int, isMovie: Bool) async -> Bool {
        let urls = getServerURLs(tmdbID: tmdbID, imdbID: nil, isMovie: isMovie)
        
        return await withTaskGroup(of: Bool.self) { group in
            for urlString in urls {
                group.addTask {
                    guard let url = URL(string: urlString) else { return false }
                    var request = URLRequest(url: url)
                    request.httpMethod = "HEAD"
                    request.setValue(self.userAgent, forHTTPHeaderField: "User-Agent")
                    request.setValue("https://google.com", forHTTPHeaderField: "Referer")
                    request.timeoutInterval = 2.5
                    
                    do {
                        let (_, response) = try await URLSession.shared.data(for: request)
                        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode < 400 {
                            return true
                        }
                    } catch {
                        // تجاهل الخطأ
                    }
                    return false
                }
            }
            
            for await isAvailable in group {
                if isAvailable { return true }
            }
            
            return false
        }
    }
}




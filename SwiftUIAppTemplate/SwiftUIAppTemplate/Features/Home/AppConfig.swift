import SwiftUI
import Foundation

class AppConfig: ObservableObject {
    static let shared = AppConfig()
    
    // الروابط
    @Published var server1: String = "https://vidsrc.me"
    @Published var server2: String = "https://vidlink.pro"
    
    // الإعلانات
    @Published var bannerMessage: String = ""
    @Published var showBanner: Bool = false
    
    // الصيانة والتحديث
    @Published var isMaintenance: Bool = false
    @Published var appVersion: String = "1.0"
    
    // المؤقت (المراقب الصامت)
    private var timer: Timer?
    
    init() {
        fetchConfig()
        startRealTimeWatcher()
    }
    
    func startRealTimeWatcher() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.fetchConfig()
        }
    }
    
    func fetchConfig() {
        let urlString = "https://firestore.googleapis.com/v1/projects/iccbox/databases/(default)/documents/settings/config"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData 
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { return }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let fields = json["fields"] as? [String: Any] {
                
                DispatchQueue.main.async {
                    // سحب الروابط
                    if let s1 = fields["serverUrl"] as? [String: Any] { 
                        let newVal = s1["stringValue"] as? String ?? self.server1
                        if self.server1 != newVal { self.server1 = newVal }
                    }
                    if let s2 = fields["serverUrl2"] as? [String: Any] { 
                        let newVal = s2["stringValue"] as? String ?? self.server2
                        if self.server2 != newVal { self.server2 = newVal }
                    }
                    
                    // سحب الإعلان
                    if let msg = (fields["bannerMessage"] as? [String: Any]) ?? (fields["bannerMassage"] as? [String: Any]) { 
                        let newVal = msg["stringValue"] as? String ?? ""
                        if self.bannerMessage != newVal { self.bannerMessage = newVal }
                    }
                    
                    // 🌟 سحب حالة الإعلان مع حركة الأنيميشن (تقلص وتلاشي)
                    if let show = fields["showBanner"] as? [String: Any] { 
                        let newVal = show["booleanValue"] as? Bool ?? false
                        if self.showBanner != newVal { 
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                self.showBanner = newVal 
                            }
                        }
                    }
                    
                    // سحب حالة الصيانة
                    if let maint = fields["isMaintenance"] as? [String: Any] { 
                        let newVal = maint["booleanValue"] as? Bool ?? false
                        if self.isMaintenance != newVal { self.isMaintenance = newVal }
                    }
                    
                    // سحب رقم الإصدار
                    if let ver = fields["appVersion"] as? [String: Any] { 
                        let newVal = ver["stringValue"] as? String ?? "1.0"
                        if self.appVersion != newVal { self.appVersion = newVal }
                    }
                }
            }
        }.resume()
    }
}

// ==========================================
// 📊 محرك الإحصائيات الخاص (صنع خصيصاً لتجاوز قيود الآيباد)
// ==========================================
class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    // دالة تسجيل نقرات الأفلام
    func logMovieClick(movieName: String) {
        // ننشئ مجلد جديد بقاعدة البيانات اسمه "movie_clicks"
        let urlString = "https://firestore.googleapis.com/v1/projects/iccbox/databases/(default)/documents/movie_clicks"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST" // POST يعني "إرسال بيانات جديدة"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 📝 ترتيب البيانات اللي راح تنرسل للوحة
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy HH:mm:ss"
        let currentTime = formatter.string(from: Date())
        
        let body: [String: Any] = [
            "fields": [
                "movieName": ["stringValue": movieName],
                "clickTime": ["stringValue": currentTime],
                "device": ["stringValue": "iOS/iPadOS"]
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        // 🚀 إطلاق الإرسال بالخفاء بدون ما يحس المستخدم
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ خطأ في إرسال الإحصائيات: \(error.localizedDescription)")
                return
            }
            print("📊 تم تسجيل نقرة للفيلم: \(movieName) بنجاح!")
        }.resume()
    }
}

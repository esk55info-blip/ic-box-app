import Foundation
import SwiftUI

struct FirestoreConfigResponse: Codable { let fields: ConfigFields? }
struct ConfigFields: Codable {
    let showMovies: FirestoreBool?
    let showSeries: FirestoreBool?
    let showTurkish: FirestoreBool?
    let showArabicDubbed: FirestoreBool?
    let showAsian: FirestoreBool?
    let showAnime: FirestoreBool?
    let showTVShows: FirestoreBool?
    let showCartoon: FirestoreBool?
    let showCompanies: FirestoreBool?
    let showStars: FirestoreBool?
}
struct FirestoreBool: Codable { let booleanValue: Bool }

class AppConfigManager: ObservableObject {
    static let shared = AppConfigManager()
    
    @Published var showMovies: Bool = true
    @Published var showSeries: Bool = true
    @Published var showTurkish: Bool = true
    @Published var showArabicDubbed: Bool = true
    @Published var showAsian: Bool = true
    @Published var showAnime: Bool = true
    @Published var showTVShows: Bool = true
    @Published var showCartoon: Bool = true
    @Published var showCompanies: Bool = true
    @Published var showStars: Bool = true
    
    private let firestoreURL = "https://firestore.googleapis.com/v1/projects/iccbox/databases/(default)/documents/settings/config2"
    private var liveTimer: Timer?
    
    init() {
        fetchConfig()
        startLiveListener() // تشغيل الرادار الحي
    }
    
    // يفحص فايربيس كل 3 ثواني لتطبيق التغييرات فورا
    func startLiveListener() {
        liveTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            self.fetchConfig()
        }
    }
    
    func fetchConfig() {
        guard let url = URL(string: firestoreURL) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let response = try? JSONDecoder().decode(FirestoreConfigResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.showMovies = response.fields?.showMovies?.booleanValue ?? true
                    self.showSeries = response.fields?.showSeries?.booleanValue ?? true
                    self.showTurkish = response.fields?.showTurkish?.booleanValue ?? true
                    self.showArabicDubbed = response.fields?.showArabicDubbed?.booleanValue ?? true
                    self.showAsian = response.fields?.showAsian?.booleanValue ?? true
                    self.showAnime = response.fields?.showAnime?.booleanValue ?? true
                    self.showTVShows = response.fields?.showTVShows?.booleanValue ?? true
                    self.showCartoon = response.fields?.showCartoon?.booleanValue ?? true
                    self.showCompanies = response.fields?.showCompanies?.booleanValue ?? true
                    self.showStars = response.fields?.showStars?.booleanValue ?? true
                }
            }
        }.resume()
    }
}

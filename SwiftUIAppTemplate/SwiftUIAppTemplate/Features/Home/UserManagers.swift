import Foundation
import SwiftUI

// ⭐️ مدير المفضلة (يحفظ الفيلم كاملاً كـ Data)
class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    
    @Published var favoriteMovies: [MovieItem] = [] {
        didSet {
            if let encoded = try? JSONEncoder().encode(favoriteMovies) {
                UserDefaults.standard.set(encoded, forKey: "saved_full_favorites")
            }
        }
    }
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "saved_full_favorites"),
           let decoded = try? JSONDecoder().decode([MovieItem].self, from: data) {
            self.favoriteMovies = decoded
        }
    }
    
    func isFavorite(movie: MovieItem) -> Bool {
        return favoriteMovies.contains(where: { $0.id == movie.id })
    }
    
    func toggleFavorite(movie: MovieItem) {
        if let index = favoriteMovies.firstIndex(where: { $0.id == movie.id }) {
            favoriteMovies.remove(at: index)
        } else {
            favoriteMovies.append(movie)
        }
    }
}

// 🎯 مدير تفاعلات المستخدم (يحفظ الأفلام كاملة لكل قائمة على حدة)
class UserActionsManager: ObservableObject {
    static let shared = UserActionsManager()
    
    @Published var watchLaterMovies: [MovieItem] = [] {
        didSet { saveList(watchLaterMovies, key: "saved_full_wl") }
    }
    @Published var likedMovies: [MovieItem] = [] {
        didSet { saveList(likedMovies, key: "saved_full_likes") }
    }
    @Published var subscribedMovies: [MovieItem] = [] {
        didSet { saveList(subscribedMovies, key: "saved_full_subs") }
    }
    @Published var dislikedIds: [Int] = [] {
        didSet { UserDefaults.standard.set(dislikedIds, forKey: "saved_dislikes_ids") }
    }
    
    init() {
        self.watchLaterMovies = loadList(key: "saved_full_wl")
        self.likedMovies = loadList(key: "saved_full_likes")
        self.subscribedMovies = loadList(key: "saved_full_subs")
        self.dislikedIds = UserDefaults.standard.array(forKey: "saved_dislikes_ids") as? [Int] ?? []
    }
    
    private func saveList(_ list: [MovieItem], key: String) {
        if let encoded = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    private func loadList(key: String) -> [MovieItem] {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([MovieItem].self, from: data) {
            return decoded
        }
        return []
    }
    
    func isWatchLater(movie: MovieItem) -> Bool { watchLaterMovies.contains(where: { $0.id == movie.id }) }
    func toggleWatchLater(movie: MovieItem) {
        if let index = watchLaterMovies.firstIndex(where: { $0.id == movie.id }) {
            watchLaterMovies.remove(at: index)
        } else {
            watchLaterMovies.append(movie)
        }
    }
    
    func isSubscribed(movie: MovieItem) -> Bool { subscribedMovies.contains(where: { $0.id == movie.id }) }
    func toggleSubscribe(movie: MovieItem) {
        if let index = subscribedMovies.firstIndex(where: { $0.id == movie.id }) {
            subscribedMovies.remove(at: index)
        } else {
            subscribedMovies.append(movie)
        }
    }
    
    func isLiked(movie: MovieItem) -> Bool { likedMovies.contains(where: { $0.id == movie.id }) }
    func setLiked(movie: MovieItem, status: Bool) {
        if status {
            if !likedMovies.contains(where: { $0.id == movie.id }) {
                likedMovies.append(movie)
            }
            dislikedIds.removeAll(where: { $0 == movie.id })
        } else {
            likedMovies.removeAll(where: { $0.id == movie.id })
        }
    }
    
    func isDisliked(id: Int) -> Bool { dislikedIds.contains(id) }
    func setDisliked(movie: MovieItem, status: Bool) {
        if status {
            if !dislikedIds.contains(movie.id) {
                dislikedIds.append(movie.id)
            }
            likedMovies.removeAll(where: { $0.id == movie.id })
        } else {
            likedMovies.removeAll(where: { $0.id == movie.id })
        }
    }
}

struct WatchHistoryItem: Identifiable, Codable {
    var id: Int
    var movie: MovieItem
    var progress: Double
    var lastWatchedDate: Date
}

class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    
    @Published var historyItems: [WatchHistoryItem] = [] {
        didSet {
            if let encoded = try? JSONEncoder().encode(historyItems) {
                UserDefaults.standard.set(encoded, forKey: "saved_watch_history_progress")
            }
        }
    }
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "saved_watch_history_progress"),
           let decoded = try? JSONDecoder().decode([WatchHistoryItem].self, from: data) {
            self.historyItems = decoded
        }
    }
    
    func updateProgress(for movie: MovieItem, progress: Double) {
        if let index = historyItems.firstIndex(where: { $0.movie.id == movie.id }) {
            historyItems[index].progress = progress
            historyItems[index].lastWatchedDate = Date()
            let item = historyItems.remove(at: index)
            historyItems.insert(item, at: 0)
        } else {
            let newItem = WatchHistoryItem(id: movie.id, movie: movie, progress: progress, lastWatchedDate: Date())
            historyItems.insert(newItem, at: 0)
        }
        if historyItems.count > 10 { historyItems.removeLast() }
        objectWillChange.send()
    }
}

class CloudAuthManager: ObservableObject {
    static let shared = CloudAuthManager()
    
    @Published var isCloudAuthenticated = false
    @Published var cloudUserEmail: String = ""
    @Published var statusMessage: String = ""
    
    func registerCloudUser(email: String, pass: String, completion: @escaping (Bool) -> Void) {
        completion(true)
    }
    
    func loginCloudUser(email: String, pass: String, completion: @escaping (Bool) -> Void) {
        completion(true)
    }
    
    func logoutCloud() {
        self.isCloudAuthenticated = false
        self.cloudUserEmail = ""
    }
}

// ==========================================
// 🔐 نموذج وقاعدة بيانات المستخدم الحقيقي الآمنة
// ==========================================
struct RealUserAccount: Identifiable, Codable {
    var id: String = UUID().uuidString
    var fullName: String          // الاسم الحقيقي أو اللقب الجديد
    var username: String          // اسم المستخدم (اليوزر)
    var email: String             // البريد الإلكتروني الحقيقي
    var passwordHash: String      // كلمة المرور
    var bio: String = "النبذه التعريفية"
    var profileImageData: Data? = nil // صورة البروفايل من الاستوديو
    var isEmailVerified: Bool = false // حالة تأكيد البريد
    var verificationCode: String = "" // رمز تأكيد الإيميل
}

class RealAuthManager: ObservableObject {
    static let shared = RealAuthManager()
    
    @Published var currentUser: RealUserAccount? = nil
    @Published var errorMessage: String = ""
    
    private let dbKey = "real_app_users_database_v3"
    private let sessionKey = "real_active_user_email_v3"
    
    init() {
        loadSession()
    }
    
    // 🌐 دالة إرسال الـ OTP الحقيقي عبر خدمة Resend السحابية مع مفتاحك الخاص
    func sendRealOTPEmail(toEmail: String, otpCode: String, completion: @escaping (Bool) -> Void) {
        let urlString = "https://api.resend.com/emails"
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 🔑 مفتاح الـ API الخاص بك المدمج هنا
        let apiKey = "Re_SczYUJJv_FsG8b9RjC4Pifk78RiT42yf6"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "from": "onboarding@resend.dev",
            "to": [toEmail],
            "subject": "رمز تأكيد الحساب (OTP) - تطبيق الأفلام",
            "html": """
                <div dir="rtl" style="font-family: Arial, sans-serif; padding: 20px; background-color: #f4f4f4;">
                    <div style="max-width: 500px; margin: auto; background: white; padding: 20px; border-radius: 10px;">
                        <h2 style="color: #333;">مرحباً بك في تطبيقنا! 🎬</h2>
                        <p style="color: #555;">لقد طلبت إنشاء حساب جديد، رمز التحقق الخاص بك هو:</p>
                        <div style="font-size: 24px; font-weight: bold; color: #007bff; text-align: center; margin: 20px 0; padding: 10px; background: #e9ecef; border-radius: 5px;">
                            \(otpCode)
                        </div>
                        <p style="color: #777; font-size: 12px;">إذا لم تقم بطلب هذا الرمز، يمكنك تجاهل هذه الرسالة.</p>
                    </div>
                </div>
                """
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            completion(false)
            return
        }
        
        request.httpBody = httpBody
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                DispatchQueue.main.async { completion(true) }
            } else {
                DispatchQueue.main.async { completion(false) }
            }
        }.resume()
    }
    
    // 1️⃣ التحقق الصارم وإنشاء الحساب الحقيقي مع إرسال رمز التأكيد الفعلي للإيميل
    func register(fullName: String, username: String, email: String, pass: String, confirmPass: String) -> Bool {
        // التحقق من الاسم الحقيقي
        guard !fullName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "يرجى إدخال الاسم الحقيقي أو اللقب بشكل صحيح."
            return false
        }
        
        // شروط اليوزر: لا يقل عن 3 أحرف/أرقام/رموز وبدون مسافات
        let usernameRegex = "^[a-zA-Z0-9_\\-\\.\\$#@!]{3,}$"
        let usernameTest = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        guard usernameTest.evaluate(with: username) else {
            errorMessage = "اسم المستخدم (اليوزر) يجب أن يكون 3 خانات على الأقل بدون مسافات فارغة."
            return false
        }
        
        // شروط الإيميل الحقيقي
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailTest.evaluate(with: email) else {
            errorMessage = "يرجى إدخال بريد إلكتروني حقيقي وصحيح."
            return false
        }
        
        // شروط كلمة المرور: 6 خانات فما فوق
        guard pass.count >= 6 else {
            errorMessage = "كلمة المرور يجب أن تكون 6 رموز/أرقام على الأقل."
            return false
        }
        
        // مطابقة كلمة المرور الثانية تماماً
        guard pass == confirmPass else {
            errorMessage = "كلمتا المرور غير متطابقتين تماماً."
            return false
        }
        
        var accounts = fetchAllAccounts()
        
        // التحقق من عدم تكرار الإيميل أو اليوزر بقاعدة البيانات
        if accounts.contains(where: { $0.email.lowercased() == email.lowercased() }) {
            errorMessage = "هذا البريد الإلكتروني مسجل مسبقاً بقاعدة البيانات."
            return false
        }
        if accounts.contains(where: { $0.username.lowercased() == username.lowercased() }) {
            errorMessage = "اسم المستخدم (اليوزر) هذا محجوز مسبقاً، اختر غيره."
            return false
        }
        
        // توليد رمز تأكيد إيميل حقيقي (مكون من 4 أرقام)
        let generatedCode = String(format: "%04d", Int.random(in: 1000...9999))
        
        // إنشاء المستخدم الجديد مع تعيين حالة الحساب
        let newUser = RealUserAccount(
            fullName: fullName,
            username: username,
            email: email,
            passwordHash: pass,
            isEmailVerified: false, // يبدأ غير مؤكد لحين إدخال الرمز
            verificationCode: generatedCode
        )
        
        accounts.append(newUser)
        saveAllAccounts(accounts)
        
        // تسجيل الدخول المبدئي
        self.currentUser = newUser
        UserDefaults.standard.set(newUser.email, forKey: sessionKey)
        
        // 🚀 إرسال الـ OTP الحقيقي عبر الإنترنت إلى إيميل المستخدم الفعلي باستخدام Resend
        sendRealOTPEmail(toEmail: email, otpCode: generatedCode) { success in
            DispatchQueue.main.async {
                if success {
                    self.errorMessage = "تم إرسال رسالة الـ OTP بنجاح إلى بريدك الإلكتروني! ✉️"
                } else {
                    self.errorMessage = "تعذر إرسال الإيميل، تأكد من الاتصال بالإنترنت."
                }
            }
        }
        
        return true
    }
    
    // 2️⃣ تأكيد البريد الإلكتروني عبر الرمز المرسل
    func verifyEmail(withCode code: String) -> Bool {
        guard var user = currentUser else { return false }
        if user.verificationCode == code {
            user.isEmailVerified = true
            updateUserInDatabase(user)
            self.currentUser = user
            errorMessage = "تم تأكيد الحساب والبريد الإلكتروني بنجاح! ✅"
            return true
        } else {
            errorMessage = "رمز التأكيد غير صحيح، يرجى إدخال الرمز المرسل بدقة."
            return false
        }
    }
    
    // 3️⃣ تسجيل الدخول (بالإيميل أو اليوزر + مطابقة كلمة المرور بالقاعدة)
    func login(identifier: String, pass: String) -> Bool {
        let accounts = fetchAllAccounts()
        
        // البحث إما بالإيميل أو اليوزر مع فحص تطابق كلمة المرور بدقة
        if let user = accounts.first(where: { ($0.email.lowercased() == identifier.lowercased() || $0.username.lowercased() == identifier.lowercased()) && $0.passwordHash == pass }) {
            self.currentUser = user
            UserDefaults.standard.set(user.email, forKey: sessionKey)
            errorMessage = ""
            return true
        } else {
            errorMessage = "خطأ: البريد الإلكتروني/اسم المستخدم أو كلمة المرور غير مطابقة لما موجود بقاعدة البيانات!"
            return false
        }
    }
    
    // 4️⃣ تحديث بيانات الملف الشخصي (الاسم الحقيقي، اليوزر، البايو، الصورة، وكلمة المرور)
    func updateProfile(newFullName: String, newUsername: String, newBio: String, newPassword: String?, imageData: Data?) {
        guard var user = currentUser else { return }
        
        let accounts = fetchAllAccounts()
        
        
        guard !newFullName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "الاسم الحقيقي لا يمكن أن يكون فارغاً."
            return
        }
        user.fullName = newFullName
        
        // التحقق من أن اليوزر الجديد غير مأخوذ من قبل شخص آخر
        if newUsername != user.username {
            let usernameRegex = "^[a-zA-Z0-9_\\-\\.\\$#@!]{3,}$"
            let usernameTest = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
            guard usernameTest.evaluate(with: newUsername) else {
                errorMessage = "اليوزر الجديد غير صالح (أقل شي 3 خانات وبدون مسافات)."
                return
            }
            if accounts.contains(where: { $0.username.lowercased() == newUsername.lowercased() }) {
                errorMessage = "هذا اليوزر مستخدم بالفعل من قبل شخص آخر في المنصة."
                return
            }
            user.username = newUsername
        }
        
        user.bio = newBio
        if let img = imageData {
            user.profileImageData = img
        }
        
        if let pass = newPassword, !pass.isEmpty {
            guard pass.count >= 6 else {
                errorMessage = "كلمة المرور الجديدة يجب ألا تقل عن 6 خانات."
                return
            }
            user.passwordHash = pass
        }
        
        // حفظ التحديثات بقاعدة البيانات
        updateUserInDatabase(user)
        self.currentUser = user
        errorMessage = "تم تحديث الملف الشخصي وحفظ البيانات بأمان بنجاح! ✅"
    }
    
    // تسجيل الخروج ونظافة الجلسة
    func logout() {
        self.currentUser = nil
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }
    
    private func loadSession() {
        if let email = UserDefaults.standard.string(forKey: sessionKey) {
            let accounts = fetchAllAccounts()
            self.currentUser = accounts.first(where: { $0.email == email })
        }
    }
    
    private func fetchAllAccounts() -> [RealUserAccount] {
        if let data = UserDefaults.standard.data(forKey: dbKey),
           let decoded = try? JSONDecoder().decode([RealUserAccount].self, from: data) {
            return decoded
        }
        return []
    }
    
    private func saveAllAccounts(_ accounts: [RealUserAccount]) {
        if let encoded = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(encoded, forKey: dbKey)
        }
    }
    
    private func updateUserInDatabase(_ updatedUser: RealUserAccount) {
        var accounts = fetchAllAccounts()
        if let index = accounts.firstIndex(where: { $0.email == updatedUser.email }) {
            accounts[index] = updatedUser
            saveAllAccounts(accounts)
        }
    }
}



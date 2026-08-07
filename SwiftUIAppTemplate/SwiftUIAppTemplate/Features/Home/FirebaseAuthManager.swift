import Foundation
import SwiftUI
import UIKit // نحتاجها لضغط الصورة قبل الرفع

// هيكل المستخدم (يحتوي على الصورة والنبذة)
struct AppUser: Codable {
    var id: String
    var email: String
    var displayName: String
    var bio: String = "مشاهد سينمائي 🎬"
    var profileImageData: Data? = nil
}

class FirebaseAuthManager: ObservableObject {
    static let shared = FirebaseAuthManager()
    
    @Published var currentUser: AppUser? = nil
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    
    // 🔑 1. مفتاح الـ API الخاص بـ Auth (جاهز)
    private let apiKey = "AIzaSyCVFkHcmUMYuQaYOkW83uNXash6CnHC5lI"
    
    // 🌐 2. رابط قاعدة البيانات Realtime Database (جاهز ومضبوط)
    private let databaseURL = "https://iccbox-default-rtdb.asia-southeast1.firebasedatabase.app/" 
    
    private let sessionKey = "firebase_active_user_v1"
    
    init() {
        loadSession()
    }
    
    // ==========================================
    // ☁️ دوال الرفع والسحب السحابية (Realtime Database)
    // ==========================================
    
    // رفع بروفايل المستخدم للسحابة
    private func saveProfileToCloud(user: AppUser) {
        let urlString = "\(databaseURL)users/\(user.id).json"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT" // نستخدم PUT لإنشاء أو تحديث البيانات
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // تحويل الصورة إلى نص Base64 حتى تنحفظ بسهولة في فايربيس
        var base64Image = ""
        if let data = user.profileImageData {
            base64Image = data.base64EncodedString()
        }
        
        let body: [String: Any] = [
            "displayName": user.displayName,
            "bio": user.bio,
            "profileImageBase64": base64Image
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request).resume() // الرفع يتم بالخلفية بهدوء
    }
    
    // سحب بروفايل المستخدم من السحابة عند تسجيل الدخول
    private func fetchProfileFromCloud(userId: String, email: String, fallbackName: String, completion: @escaping (AppUser) -> Void) {
        let urlString = "\(databaseURL)users/\(userId).json"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            var finalUser = AppUser(id: userId, email: email, displayName: fallbackName)
            
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let name = json["displayName"] as? String { finalUser.displayName = name }
                if let bio = json["bio"] as? String { finalUser.bio = bio }
                if let base64Image = json["profileImageBase64"] as? String, !base64Image.isEmpty {
                    finalUser.profileImageData = Data(base64Encoded: base64Image)
                }
            }
            
            DispatchQueue.main.async { completion(finalUser) }
        }.resume()
    }
    
    // ==========================================
    // 🔐 دوال تسجيل الدخول والإنشاء
    // ==========================================
    
    func register(name: String, email: String, pass: String, completion: @escaping (Bool) -> Void) {
        guard !name.isEmpty, !email.isEmpty, pass.count >= 6 else {
            self.errorMessage = "تأكد من تعبئة جميع الحقول، وكلمة المرور 6 أحرف فأكثر."
            completion(false)
            return
        }
        
        self.isLoading = true
        self.errorMessage = ""
        
        let urlString = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=\(apiKey)"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["email": email, "password": pass, "returnSecureToken": true]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let errorObj = json["error"] as? [String: Any], let message = errorObj["message"] as? String {
                        self.handleFirebaseError(message: message)
                        completion(false)
                        return
                    }
                    
                    if let localId = json["localId"] as? String {
                        let newUser = AppUser(id: localId, email: email, displayName: name)
                        self.currentUser = newUser
                        self.saveSession(account: newUser)
                        self.saveProfileToCloud(user: newUser) // ☁️ رفع البيانات للسحابة فوراً
                        completion(true)
                    }
                } else {
                    self.errorMessage = "حدث خطأ في الاتصال بالخادم."
                    completion(false)
                }
            }
        }.resume()
    }
    
    func login(email: String, pass: String, completion: @escaping (Bool) -> Void) {
        guard !email.isEmpty, !pass.isEmpty else {
            self.errorMessage = "يرجى إدخال البريد الإلكتروني وكلمة المرور."
            completion(false)
            return
        }
        
        self.isLoading = true
        self.errorMessage = ""
        
        let urlString = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=\(apiKey)"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["email": email, "password": pass, "returnSecureToken": true]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let errorObj = json["error"] as? [String: Any], let message = errorObj["message"] as? String {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.handleFirebaseError(message: message)
                        completion(false)
                    }
                    return
                }
                
                if let localId = json["localId"] as? String, let userEmail = json["email"] as? String {
                    // ☁️ الدخول نجح للـ Auth، الآن نسحب الصورة والاسم والنبذة من السحابة!
                    self.fetchProfileFromCloud(userId: localId, email: userEmail, fallbackName: "مستخدم") { fullUser in
                        self.isLoading = false
                        self.currentUser = fullUser
                        self.saveSession(account: fullUser)
                        completion(true)
                    }
                }
            }
        }.resume()
    }
    
    func logout() {
        self.currentUser = nil
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }
    
    // ==========================================
    // ✏️ دوال التعديل وتغيير كلمة المرور
    // ==========================================
    
    func updateProfile(newName: String, newBio: String, imageData: Data?) {
        guard var user = currentUser else { return }
        
        if !newName.trimmingCharacters(in: .whitespaces).isEmpty {
            user.displayName = newName
        }
        user.bio = newBio
        
        // 🗜️ ضغط الصورة القوي حتى تنرفع للسحابة بسرعة بدون لاك (تقليل الجودة إلى 10%)
        if let data = imageData, let uiImage = UIImage(data: data) {
            user.profileImageData = uiImage.jpegData(compressionQuality: 0.1)
        }
        
        self.currentUser = user
        saveSession(account: user) 
        
        // ☁️ حفظ التحديثات فوراً في السحابة
        saveProfileToCloud(user: user)
    }
    
    func resetPassword(email: String, completion: @escaping (Bool, String) -> Void) {
        let urlString = "https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=\(apiKey)"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["requestType": "PASSWORD_RESET", "email": email]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, _ in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    completion(true, "تم إرسال رابط تغيير كلمة المرور بنجاح! ✉️")
                } else {
                    completion(false, "فشل الإرسال، تأكد من صحة البريد المدخل.")
                }
            }
        }.resume()
    }
    
    // ==========================================
    // دوال مساعدة
    // ==========================================
    
    private func handleFirebaseError(message: String) {
        if message.contains("EMAIL_EXISTS") { self.errorMessage = "هذا البريد مسجل مسبقاً، قم بتسجيل الدخول." }
        else if message.contains("INVALID_LOGIN_CREDENTIALS") || message.contains("INVALID_PASSWORD") { self.errorMessage = "البريد الإلكتروني أو كلمة المرور غير صحيحة." }
        else if message.contains("INVALID_EMAIL") { self.errorMessage = "صيغة البريد غير صحيحة." }
        else if message.contains("WEAK_PASSWORD") { self.errorMessage = "كلمة المرور ضعيفة جداً." }
        else { self.errorMessage = "حدث خطأ غير متوقع: \(message)" }
    }
    
    private func saveSession(account: AppUser) {
        if let encoded = try? JSONEncoder().encode(account) {
            UserDefaults.standard.set(encoded, forKey: sessionKey)
        }
    }
    
    private func loadSession() {
        if let data = UserDefaults.standard.data(forKey: sessionKey),
           let decoded = try? JSONDecoder().decode(AppUser.self, from: data) {
            self.currentUser = decoded
        }
    }
}
// ==========================================
// 🖥️ واجهة تسجيل الدخول والإنشاء (FirebaseAuthScreen)
// ==========================================
struct FirebaseAuthScreen: View {
    @ObservedObject private var auth = FirebaseAuthManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var isRegisterMode = true
    
    @State private var nameInput = ""
    @State private var emailInput = ""
    @State private var passInput = ""
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // شريط علوي
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 26)).foregroundColor(.white)
                    }
                    Spacer()
                    Text(isRegisterMode ? "إنشاء حساب مجاني" : "تسجيل الدخول")
                        .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                    Spacer()
                    Spacer().frame(width: 26)
                }
                .padding(.horizontal, 20).padding(.top, 20)
                
                Picker("الوضع", selection: $isRegisterMode) {
                    Text("حساب جديد").tag(true)
                    Text("تسجيل دخول").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        
                        if !auth.errorMessage.isEmpty {
                            Text(auth.errorMessage)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                        
                        if isRegisterMode {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("الاسم").font(.system(size: 12)).foregroundColor(.gray)
                                TextField("الاسم", text: $nameInput)
                                    .padding().background(Color.white.opacity(0.08)).cornerRadius(10).foregroundColor(.white)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("البريد الإلكتروني").font(.system(size: 12)).foregroundColor(.gray)
                            TextField("Email", text: $emailInput)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding().background(Color.white.opacity(0.08)).cornerRadius(10).foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("كلمة المرور").font(.system(size: 12)).foregroundColor(.gray)
                            SecureField("Password", text: $passInput)
                                .padding().background(Color.white.opacity(0.08)).cornerRadius(10).foregroundColor(.white)
                        }
                        
                        Button(action: {
                            if isRegisterMode {
                                auth.register(name: nameInput, email: emailInput, pass: passInput) { success in
                                    if success { dismiss() }
                                }
                            } else {
                                auth.login(email: emailInput, pass: passInput) { success in
                                    if success { dismiss() }
                                }
                            }
                        }) {
                            ZStack {
                                if auth.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(isRegisterMode ? "إنشاء حساب وبدء المشاهدة" : "تسجيل الدخول")
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.blue).cornerRadius(12)
                        }
                        .disabled(auth.isLoading)
                        .padding(.top, 10)
                    }
                    .padding(24)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}


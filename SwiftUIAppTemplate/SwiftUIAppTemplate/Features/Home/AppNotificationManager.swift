import Foundation
import SwiftUI

// ==========================================
// 1. هياكل فك التشفير من فايربيس
// ==========================================
struct FirestoreNotificationResponse: Codable {
    let documents: [FirestoreNotificationDoc]?
}
struct FirestoreNotificationDoc: Codable {
    let fields: NotificationFields?
}
struct NotificationFields: Codable {
    let title: FirestoreString?
    let message: FirestoreString?
    let date: FirestoreString?
}
struct FirestoreString: Codable {
    let stringValue: String
}

// ==========================================
// 2. هيكل الإشعار داخل التطبيق
// ==========================================
struct AppNotification: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let date: String
}

// ==========================================
// 3. المدير المسؤول عن جلب الإشعارات
// ==========================================
class AppNotificationManager: ObservableObject {
    static let shared = AppNotificationManager()
    
    @Published var notifications: [AppNotification] = []
    @Published var hasUnread: Bool = false
    
    // رابط مجلد الإشعارات في فايربيس
    private let firestoreURL = "https://firestore.googleapis.com/v1/projects/iccbox/databases/(default)/documents/notifications"
    
    init() {
        fetchNotifications()
    }
    
    func fetchNotifications() {
        guard let url = URL(string: firestoreURL) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let response = try? JSONDecoder().decode(FirestoreNotificationResponse.self, from: data) {
                var fetched: [AppNotification] = []
                
                for doc in response.documents ?? [] {
                    let title = doc.fields?.title?.stringValue ?? "تنبيه"
                    let msg = doc.fields?.message?.stringValue ?? ""
                    let date = doc.fields?.date?.stringValue ?? ""
                    fetched.append(AppNotification(title: title, message: msg, date: date))
                }
                
                DispatchQueue.main.async {
                    self.notifications = fetched.reversed()
                    self.hasUnread = !fetched.isEmpty
                }
            }
        }.resume()
    }
}

// ==========================================
// 4. تصميم واجهة مركز الإشعارات (شاشة كاملة)
// ==========================================
struct NotificationCenterView: View {
    let notifications: [AppNotification]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea() // شاشة سوداء بالكامل
            
            VStack(spacing: 0) {
                // شريط العنوان وزر الرجوع الكلاسيكي
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 5)
                            .padding(.trailing, 10)
                    }
                    
                    Spacer()
                    
                    Text("الإشعارات")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.trailing, 30) // لضبط التوسيط بسبب مساحة السهم
                    
                    Spacer()
                }
                .padding()
                .background(Color(red: 0.05, green: 0.05, blue: 0.05))
                
                // حالة عدم وجود إشعارات
                if notifications.isEmpty {
                    VStack(spacing: 15) {
                        Spacer()
                        Image(systemName: "bell.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("لا توجد إشعارات حالياً")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    // عرض الإشعارات على شكل صفوف
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(notifications) { notif in
                                VStack(alignment: .trailing, spacing: 8) {
                                    HStack {
                                        Text(notif.date)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text(notif.title)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text(notif.message)
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.8))
                                        .multilineTextAlignment(.trailing)
                                        .lineSpacing(4)
                                }
                                .padding(16)
                                .background(Color(red: 0.1, green: 0.1, blue: 0.12)) // لون خلفية الإشعار
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft) // الحفاظ على الاتجاه العربي
    }
}



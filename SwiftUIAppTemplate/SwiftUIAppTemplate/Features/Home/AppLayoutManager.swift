import SwiftUI

class AppLayoutManager: ObservableObject {
    static let shared = AppLayoutManager()
    
    // متتبع اتجاه الشاشة (يتحدث تلقائياً فوراً عند تدوير الجهاز)
    @Published var isLandscape: Bool = false
    
    init() {
        updateOrientation() // تعيين القيمة الابتدائية أول ما يشتغل التطبيق
        // مراقبة حساسة لتدوير الشاشة
        NotificationCenter.default.addObserver(self, selector: #selector(updateOrientation), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc private func updateOrientation() {
        DispatchQueue.main.async {
            // الطريقة الحديثة والآمنة لمعرفة دوران الشاشة بدون تحذيرات
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                self.isLandscape = windowScene.effectiveGeometry.interfaceOrientation.isLandscape
            }
        }
    }
    
    // ==========================================
    // 📱 1. فحص نوع الجهاز
    // ==========================================
    var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    // ==========================================
    // 📏 2. قياسات البوسترات (عرض وطول)
    // ==========================================
    var posterWidth: CGFloat {
        if isPad {
            // قياسات الآيباد الأصلية
            return isLandscape ? 135 : 115
        } else {
            // قياسات الآيفون الأصلية (تم إصلاح الفاصلة هنا)
            return isLandscape ? 125 : 105
        }
    }
    
    var posterHeight: CGFloat {
        if isPad {
            // قياسات الآيباد الأصلية
            return isLandscape ? 210 : 100
        } else {
            // قياسات الآيفون الأصلية
            return isLandscape ? 140 : 90
        }
    }
    
    // ==========================================
    // 🔠 3. أحجام الخطوط الرئيسية
    // ==========================================
    var titleFont: CGFloat {
        isPad ? 14 : 12
    }
    
    var subFont: CGFloat {
        isPad ? 12 : 10
    }
    
    // ==========================================
    // 📐 4. إعدادات الشبكة (Grid) لصفحة "المزيد"
    // ==========================================
    var adaptiveGrid: [GridItem] {
        // بالآيباد العمود يكون أعرض حتى ما تصير زحمة، وبالآيفون أصغر
        let minWidth: CGFloat = isPad ? (isLandscape ? 150 : 120) : 90
        return [GridItem(.adaptive(minimum: minWidth), spacing: 15)]
    }
}


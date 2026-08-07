import Foundation

class StorageManager {
    static let shared = StorageManager()
    
    private init() {}
    
    /// 🌟 1. تقييد ذاكرة التخزين المؤقت بحد أقصى (100 ميجابايت فقط)
    func setupCacheLimits() {
        let memoryLimit = 30 * 1024 * 1024 // 30 ميجابايت للرام
        let diskLimit = 70 * 1024 * 1024  // 70 ميجابايت للهارد كحد أقصى
        
        let customCache = URLCache(
            memoryCapacity: memoryLimit,
            diskCapacity: diskLimit,
            diskPath: "media_app_cache"
        )
        URLCache.shared = customCache
    }
    
    /// 🌟 2. دالة تنظيف ومسح كافة الملفات المؤقتة والبوسترات المخزنة مسبقاً
    func purgeAllCache() {
        // مسح استجابات الشبكة
        URLCache.shared.removeAllCachedResponses()
        
        let fileManager = FileManager.default
        
        // مسح مجلد Caches
        if let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            do {
                let files = try fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil)
                for file in files {
                    try fileManager.removeItem(at: file)
                }
            } catch {
                print("Error clearing caches: \(error)")
            }
        }
        
        // مسح مجلد الملفات المؤقتة tmp
        let tempURL = fileManager.temporaryDirectory
        do {
            let tempFiles = try fileManager.contentsOfDirectory(at: tempURL, includingPropertiesForKeys: nil)
            for file in tempFiles {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("Error clearing temp: \(error)")
        }
    }
}



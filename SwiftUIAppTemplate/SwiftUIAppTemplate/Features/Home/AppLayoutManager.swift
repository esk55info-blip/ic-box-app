import SwiftUI
import Combine

class AppLayoutManager: ObservableObject {
    static let shared = AppLayoutManager()
    
    @Published var isLandscape: Bool = false
    
    init() {
        updateOrientation()
        NotificationCenter.default.addObserver(self, selector: #selector(updateOrientation), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc private func updateOrientation() {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                self.isLandscape = windowScene.effectiveGeometry.interfaceOrientation.isLandscape
            }
        }
    }
    
    var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    var posterWidth: CGFloat {
        if isPad {
            return isLandscape ? 135 : 115
        } else {
            return isLandscape ? 125 : 105
        }
    }
    
    var posterHeight: CGFloat {
        if isPad {
            return isLandscape ? 210 : 100
        } else {
            return isLandscape ? 140 : 90
        }
    }
    
    var titleFont: CGFloat {
        isPad ? 14 : 12
    }
    
    var subFont: CGFloat {
        isPad ? 12 : 10
    }

    var adaptiveGrid: [GridItem] {
        let minWidth: CGFloat = isPad ? (isLandscape ? 150 : 120) : 90
        return [GridItem(.adaptive(minimum: minWidth), spacing: 15)]
    }
}

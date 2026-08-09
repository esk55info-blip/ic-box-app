import SwiftUI

@main
struct MyApp: App {
    @StateObject private var viewModel = MovieViewModel()
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}

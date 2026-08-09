import SwiftUI

struct AppRootView: View {

    let container: AppContainer

    var body: some View {
        NavigationStack {
            HomeView()
        }
    }
}

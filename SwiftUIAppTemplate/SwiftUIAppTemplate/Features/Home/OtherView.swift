import SwiftUI

struct OtherView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: MovieViewModel
    
    // 🌟 تم الربط مع مدير فايربيس الجديد
    @ObservedObject private var authManager = FirebaseAuthManager.shared
    
    @State private var showSettings = false
    @State private var showAuthSheet = false
    
    // ✏️ حالة إظهار شاشة تعديل الملف الشخصي
    @State private var showEditProfile = false
    
    // حالات القوائم الخاصة
    @State private var showFavorites = false
    @State private var showWatchLater = false
    @State private var showLikedMovies = false
    
    let midnightNavyLine = Color(red: 0.05, green: 0.08, blue: 0.18)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // الشريط العلوي
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 42, height: 42)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    }
                    
                    Spacer()
                    
                    Button(action: { showSettings = true }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 42, height: 42)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 15)
                .padding(.bottom, 10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // ==========================================
                        // 🌟 قسم الملف الشخصي المحدث (مع زر القلم والصورة والنبذة)
                        // ==========================================
                        HStack(alignment: .center, spacing: 20) {
                            
                            // المعلومات والاسم والنبذة وزر القلم (في اليمين)
                            VStack(alignment: .trailing, spacing: 6) {
                                HStack(spacing: 8) {
                                    // زر القلم للتعديل (يظهر فقط إذا كان المستخدم مسجل دخول)
                                    if authManager.currentUser != nil {
                                        Button(action: { showEditProfile = true }) {
                                            Image(systemName: "pencil.circle.fill")
                                                .font(.system(size: 22))
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    
                                    Text(authManager.currentUser?.displayName ?? "زائر الكريم")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                Text(authManager.currentUser?.email ?? "يرجى تسجيل الدخول مجاناً")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                
                                Text(authManager.currentUser?.bio ?? "مشاهد سينمائي 🎬")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.trailing)
                                    .lineLimit(2)
                                
                                if authManager.currentUser == nil {
                                    Button(action: { showAuthSheet = true }) {
                                        Text("تسجيل الدخول / إنشاء حساب")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.blue)
                                            .clipShape(Capsule())
                                    }
                                    .padding(.top, 6)
                                } else {
                                    Button(action: { authManager.logout() }) {
                                        Text("تسجيل الخروج")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.red)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.red.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                    .padding(.top, 6)
                                }
                            }
                            
                            Spacer()
                            
                            // 🖼️ عرض الصورة الشخصية الحقيقية من الاستوديو أو الحرف الافتراضي
                            ZStack {
                                if let data = authManager.currentUser?.profileImageData, let uiImg = UIImage(data: data) {
                                    Image(uiImage: uiImg)
                                        .resizable().scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                                } else {
                                    Circle()
                                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 80, height: 80)
                                    
                                    if let firstChar = authManager.currentUser?.displayName.first {
                                        Text(String(firstChar))
                                            .font(.system(size: 35, weight: .bold))
                                            .foregroundColor(.white)
                                    } else {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 35))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .environment(\.layoutDirection, .rightToLeft)
                        
                        Rectangle()
                            .fill(midnightNavyLine)
                            .frame(height: 1.5)
                            .padding(.horizontal, 20)
                        
                        // أزرار القوائم التفاعلية
                        VStack(spacing: 12) {
                            Button(action: { showFavorites = true }) {
                                profileRowItem(icon: "heart.fill", iconColor: .red, title: "المفضلة المحفوظة")
                            }
                            Button(action: { showWatchLater = true }) {
                                profileRowItem(icon: "clock.fill", iconColor: .blue, title: "قائمة المشاهدة لاحقاً")
                            }
                            Button(action: { showLikedMovies = true }) {
                                profileRowItem(icon: "hand.thumbsup.fill", iconColor: .cyan, title: "الأفلام المعجب بها")
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 40)
                        
                        HStack(spacing: 6) {
                            Text("حقوق النشر © 2026").font(.system(size: 11)).foregroundColor(.gray)
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .fullScreenCover(isPresented: $showSettings) { SettingsView() }
        // 🌟 ربط الشاشات (التسجيل والتعديل والقوائم)
        .sheet(isPresented: $showAuthSheet) { FirebaseAuthScreen() }
        .sheet(isPresented: $showEditProfile) { EditProfileScreen() } // تم إضافة شاشة التعديل هنا
        .sheet(isPresented: $showFavorites) { UserMoviesListView(title: "المفضلة المحفوظة", allMovies: viewModel.movies) }
        .sheet(isPresented: $showWatchLater) { UserMoviesListView(title: "قائمة المشاهدة لاحقاً", allMovies: viewModel.movies) }
        .sheet(isPresented: $showLikedMovies) { UserMoviesListView(title: "الأفلام المعجب بها", allMovies: viewModel.movies) }
    }
    
    @ViewBuilder
    private func profileRowItem(icon: String, iconColor: Color, title: String) -> some View {
        HStack {
            Image(systemName: icon).font(.system(size: 18)).foregroundColor(iconColor)
            Text(title).font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.left").font(.system(size: 14)).foregroundColor(.gray)
        }
        .padding(.horizontal, 16).padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}
// ==========================================
// 📺 شاشة عرض الأفلام المحفوظة (المفضلة / لاحقاً / المعجب بها)
// ==========================================
struct UserMoviesListView: View {
    var title: String
    var allMovies: [MovieItem]
    @Environment(\.dismiss) var dismiss
    @State private var selectedMovie: MovieItem? = nil
    
    var displayedMovies: [MovieItem] {
        if title == "المفضلة المحفوظة" {
            return FavoritesManager.shared.favoriteMovies
        } else if title == "قائمة المشاهدة لاحقاً" {
            return UserActionsManager.shared.watchLaterMovies
        } else if title == "الأفلام المعجب بها" {
            return UserActionsManager.shared.likedMovies
        }
        return []
    }
    
    let columns = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Spacer().frame(width: 26)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                
                ScrollView(showsIndicators: false) {
                    let currentList = displayedMovies
                    if currentList.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "film.stack")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(.top, 100)
                            Text("لا توجد عناصر في هذه القائمة حتى الآن")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    } else {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(currentList) { movie in
                                Button(action: {
                                    selectedMovie = movie
                                }) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        AsyncImage(url: movie.imageUrl) { image in
                                            image.resizable().scaledToFill()
                                        } placeholder: {
                                            Rectangle().fill(Color.white.opacity(0.05))
                                        }
                                        .frame(height: 160)
                                        .cornerRadius(12)
                                        .clipped()
                                        
                                        Text(movie.displayName)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.9))
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .fullScreenCover(item: $selectedMovie) { movie in
            DetailAndPlayerView(item: movie, allMovies: allMovies)
        }
    }
}

// ==========================================
// ⚙️ شاشة الإعدادات العامة
// ==========================================
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    Text("الإعدادات")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Spacer().frame(width: 28)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                Text("شاشة الإعدادات العامة")
                    .foregroundColor(.gray)
                
                Spacer()
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

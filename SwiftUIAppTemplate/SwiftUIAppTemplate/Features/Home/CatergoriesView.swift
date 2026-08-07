import SwiftUI

struct CustomGenre: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let movieParams: String 
    let tvParams: String    
    let colors: [Color]
}

struct LanguageOption: Hashable {
    let name: String
    let code: String
}

struct SortOption: Hashable {
    let name: String
    let queryKey: String
}

struct CategoriesView: View {
    @StateObject private var viewModel = MovieViewModel()
    
    @State private var isMovieSelection = true
    @State private var selectedCategory: CustomGenre? = nil
    @State private var isDetailActive = false
    @State private var selectedMovieToPlay: MovieItem? = nil
    
    @State private var selectedLanguage = LanguageOption(name: "الكل", code: "all")
    @State private var selectedSort = SortOption(name: "المشاهدات", queryKey: "popularity.desc") 
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    let languagesList = [
        LanguageOption(name: "الكل", code: "all"),
        LanguageOption(name: "الإنجليزية", code: "en"),
        LanguageOption(name: "العربية", code: "ar"),
        LanguageOption(name: "الهندية", code: "hi"),
        LanguageOption(name: "الفرنسية", code: "fr"),
        LanguageOption(name: "الألمانية", code: "de"),
        LanguageOption(name: "الصينية", code: "zh"),
        LanguageOption(name: "اليابانية", code: "ja"),
        LanguageOption(name: "الكورية", code: "ko"),
        LanguageOption(name: "التركية", code: "tr"),
        LanguageOption(name: "الفارسية", code: "fa")
    ]
    
    let sortOptionsList = [
        SortOption(name: "المشاهدات", queryKey: "popularity.desc"),
        SortOption(name: "تاريخ الرفع", queryKey: "release_date.desc"),
        SortOption(name: "تصنيف الفئة", queryKey: "popularity.desc"),
        SortOption(name: "تقييم IMDB", queryKey: "vote_average.desc")
    ]
    
    let allCategories = [
        CustomGenre(name: "أكشن وحركة", icon: "flame.fill", movieParams: "&with_genres=28", tvParams: "&with_genres=10759", colors: [.red, .orange]),
        CustomGenre(name: "دراما", icon: "theatermasks.fill", movieParams: "&with_genres=18", tvParams: "&with_genres=18", colors: [.purple, .indigo]),
        CustomGenre(name: "كوميديا", icon: "face.smiling.fill", movieParams: "&with_genres=35", tvParams: "&with_genres=35", colors: [.yellow, .orange]),
        CustomGenre(name: "عائلي", icon: "figure.2.and.child.holdinghands", movieParams: "&with_genres=10751", tvParams: "&with_genres=10762", colors: [.green, .mint]),
        CustomGenre(name: "مغامرة", icon: "compass.drawing", movieParams: "&with_genres=12", tvParams: "&with_genres=10759", colors: [.blue, .cyan]),
        CustomGenre(name: "جريمة", icon: "exclamationmark.shield.fill", movieParams: "&with_genres=80", tvParams: "&with_genres=80", colors: [Color(white: 0.15), .gray]),
        CustomGenre(name: "خيال علمي", icon: "atom", movieParams: "&with_genres=878", tvParams: "&with_genres=10765", colors: [.purple, .cyan]),
        CustomGenre(name: "رومانسي", icon: "heart.fill", movieParams: "&with_genres=10749", tvParams: "&with_genres=10766", colors: [.pink, .red]),
        CustomGenre(name: "إثارة", icon: "waveform.path.ecg", movieParams: "&with_genres=53", tvParams: "&with_genres=9648", colors: [.orange, .red]),
        CustomGenre(name: "خارق", icon: "bolt.shield.fill", movieParams: "&with_genres=14", tvParams: "&with_genres=10765", colors: [.yellow, .indigo]),
        CustomGenre(name: "غموض", icon: "eye.tunnel", movieParams: "&with_genres=9648", tvParams: "&with_genres=9648", colors: [.indigo, .blue]),
        CustomGenre(name: "انمي", icon: "sparkles", movieParams: "&with_genres=16&with_original_language=ja", tvParams: "&with_genres=16&with_original_language=ja", colors: [.cyan, .pink]),
        CustomGenre(name: "حروب", icon: "shield.fill", movieParams: "&with_genres=10752", tvParams: "&with_genres=10768", colors: [.brown, Color(white: 0.2)]),
        CustomGenre(name: "تاريخي", icon: "scroll.fill", movieParams: "&with_genres=36", tvParams: "&with_genres=18", colors: [.orange, .brown]),
        CustomGenre(name: "رعب", icon: "ghost.fill", movieParams: "&with_genres=27", tvParams: "&with_genres=9648", colors: [.red, .black]),
        CustomGenre(name: "كارتون", icon: "face.smiling", movieParams: "&with_genres=16&without_original_language=ja", tvParams: "&with_genres=16&without_original_language=ja", colors: [.green, .yellow]),
        CustomGenre(name: "خيالي", icon: "wand.and.stars", movieParams: "&with_genres=14", tvParams: "&with_genres=10765", colors: [.purple, .pink]),
        CustomGenre(name: "مدبلج عربي", icon: "globe.asia.australia.fill", movieParams: "&with_original_language=ar", tvParams: "&with_original_language=ar", colors: [.teal, .blue])
    ]
    
    // الألوان المطلوبة المخصصة للتصميم الجديد
    let midnightNavy = Color(red: 0.03, green: 0.05, blue: 0.11)
    let blueBlackCapsule = Color(red: 0.04, green: 0.07, blue: 0.15) // لون أزرق مائل للسواد فخم جداً
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isDetailActive, let category = selectedCategory {
                categoryContentGridPage(category: category)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .trailing, spacing: 20) {
                        Text("التصنيفات")
                            .font(.system(size: 26, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.top, 15)
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(allCategories) { category in
                                Button(action: {
                                    selectedCategory = category
                                    isMovieSelection = true
                                    selectedLanguage = LanguageOption(name: "الكل", code: "all")
                                    selectedSort = SortOption(name: "المشاهدات", queryKey: "popularity.desc")
                                    
                                    loadFilteredData(category: category, isMovie: true)
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        isDetailActive = true
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: category.icon)
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                            .frame(width: 40)
                                        Spacer()
                                        Text(category.name)
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 20)
                                    .frame(height: 100)
                                    .background(LinearGradient(colors: category.colors, startPoint: .leading, endPoint: .trailing).opacity(0.25))
                                    .background(Color.white.opacity(0.03))
                                    .cornerRadius(18)
                                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(LinearGradient(colors: [.white.opacity(0.15), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        Spacer().frame(height: 120)
                    }
                }
                .environment(\.layoutDirection, .rightToLeft)
            }
        }
        .fullScreenCover(item: $selectedMovieToPlay) { movie in
            DetailAndPlayerView(item: movie, allMovies: viewModel.categoryItems)
        }
    }
    
    private func loadFilteredData(category: CustomGenre, isMovie: Bool) {
        let apiKey = "cf07279214de09093fc4874b6e2ad287"
        let genreParams = isMovie ? category.movieParams : category.tvParams
        
        viewModel.fetchCategoryContent(
            isMovie: isMovie,
            genreParams: genreParams,
            langCode: selectedLanguage.code,
            sortBy: selectedSort.queryKey,
            apiKey: apiKey,
            loadNextPage: false
        )
    }
    
    @ViewBuilder
    func categoryContentGridPage(category: CustomGenre) -> some View {
        let apiKey = "cf07279214de09093fc4874b6e2ad287"
        let gridColumns = [GridItem(.adaptive(minimum: 120), spacing: 16)]
        
        VStack(spacing: 0) {
            // شريط علوي للرجوع
            HStack {
                Button(action: {
                    withAnimation(.easeInOut) {
                        isDetailActive = false
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.right")
                        Text("رجوع")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                }
                Spacer()
                Text(category.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
            .background(Color.black)
            
            // 🌟 تعديل 1: كبسولتين منفصلتين بنفس الحجم وبلون أزرق مائل للسواد للأفلام والمسلسلات
            HStack(spacing: 16) {
                Button(action: {
                    if !isMovieSelection {
                        isMovieSelection = true
                        loadFilteredData(category: category, isMovie: true)
                    }
                }) {
                    Text("أفلام")
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isMovieSelection ? blueBlackCapsule : Color.white.opacity(0.04))
                        .foregroundColor(isMovieSelection ? .white : .gray.opacity(0.8))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(isMovieSelection ? Color.blue.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
                
                Button(action: {
                    if isMovieSelection {
                        isMovieSelection = false
                        loadFilteredData(category: category, isMovie: false)
                    }
                }) {
                    Text("مسلسلات")
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(!isMovieSelection ? blueBlackCapsule : Color.white.opacity(0.04))
                        .foregroundColor(!isMovieSelection ? .white : .gray.opacity(0.8))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(!isMovieSelection ? Color.blue.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 5)
            
            // 🌟 تعديل 2: كبسولات الفلاتر مرتبة بالوسط تماماً + تعديل كلمة "الكل" فقط
            HStack(spacing: 12) {
                Spacer() // يدفع العناصر للوسط من اليمين
                
                // القائمة المنسدلة الأولى: اختيار اللغات/الدول
                Menu {
                    ForEach(languagesList, id: \.self) { lang in
                        Button(action: {
                            selectedLanguage = lang
                            loadFilteredData(category: category, isMovie: isMovieSelection)
                        }) {
                            HStack {
                                Text(lang.name)
                                if selectedLanguage.code == lang.code {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                        Text(selectedLanguage.name) // يظهر كلمة "الكل" مباشرة بدون زوائد
                            .font(.system(size: 13, weight: .bold))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(midnightNavy)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                
                // القائمة المنسدلة الثانية: فرز وترتيب القائمة
                Menu {
                    ForEach(sortOptionsList, id: \.self) { option in
                        Button(action: {
                            selectedSort = option
                            loadFilteredData(category: category, isMovie: isMovieSelection)
                        }) {
                            HStack {
                                Text(option.name)
                                if selectedSort.name == option.name {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.and.down.text.horizontal")
                            .font(.system(size: 11))
                        Text(selectedSort.name)
                            .font(.system(size: 13, weight: .bold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(midnightNavy)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                
                Spacer() // يدفع العناصر للوسط من اليسار
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            
            // شبكة البوسترات
            ScrollView {
                if viewModel.categoryItems.isEmpty {
                    VStack {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.3)
                            .padding(.top, 100)
                        Text("جاري ترتيب وتصفية المحتوى...")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                        Spacer()
                    }
                } else {
                    LazyVGrid(columns: gridColumns, spacing: 25) {
                        ForEach(viewModel.categoryItems) { item in
                            VStack {
                                AsyncImage(url: item.imageUrl) { img in
                                    img.resizable().scaledToFill()
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08))
                                }
                                .frame(width: 120, height: 175)
                                .cornerRadius(12)
                                .clipped()
                                
                                Text(item.displayName)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .multilineTextAlignment(.center)
                            }
                            .onTapGesture {
                                selectedMovieToPlay = item
                            }
                            .onAppear {
                                if item.id == viewModel.categoryItems.last?.id {
                                    let genreParams = isMovieSelection ? category.movieParams : category.tvParams
                                    viewModel.fetchCategoryContent(
                                        isMovie: isMovieSelection,
                                        genreParams: genreParams,
                                        langCode: selectedLanguage.code,
                                        sortBy: selectedSort.queryKey,
                                        apiKey: apiKey,
                                        loadNextPage: true
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 5)
                }
                
                Spacer().frame(height: 120)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

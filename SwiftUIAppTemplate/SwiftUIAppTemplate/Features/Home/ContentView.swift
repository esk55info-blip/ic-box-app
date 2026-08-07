import SwiftUI

// ==========================================
// 1. الشاشة الأساسية ومنسق التنقل العام
// ==========================================
struct ContentView: View {
    @State private var isSplashActive = true
    
    // 🌟 المتغيرات الخاصة بالتحكم السحابي (Firebase)
    @StateObject var config = AppConfig.shared
    let myCurrentVersion = "1.0" 
    
    // إجبار الآيباد على عمل كاش دائمي للبوستر على وحدة التخزين
    init() {
        let memoryCapacity = 50 * 1024 * 1024  // 40 ميجابايت للتحميل السريع المؤقت
        let diskCapacity = 100 * 1024 * 1024   // 250 ميجابايت خزن دائمي للبوسترات داخل ملفات التطبيق
        
        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: "iraq_cinema_box_posters")
        URLCache.shared = cache
    }
    
    var body: some View {
        ZStack {
            // 🛑 الشرط الأول: شاشة البداية
            if isSplashActive {
                splashView
            } 
            // 🛑 الشرط الثاني: وضع الصيانة (يقفل التطبيق)
            else if config.isMaintenance {
                maintenanceView
            } 
            // 🛑 الشرط الثالث: إصدار جديد (تحديث إجباري)
            else if config.appVersion != myCurrentVersion {
                updateView
            } 
            // ✅ الشرط الرابع: تشغيل التطبيق بشكل طبيعي
            else {
                // واجهتك الأصلية (شريط الإعلان صار بداخل HomeView بعد ما نحتاجه هنا)
                MainHomeView()
            }
        }
        // أنيميشن ناعم جداً عند تفعيل الصيانة أو التحديث من اللوحة
        .animation(.easeInOut(duration: 0.3), value: config.isMaintenance)
        .animation(.easeInOut(duration: 0.3), value: config.appVersion)
    }
    
    var splashView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                Image("logomy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    isSplashActive = false
                }
            }
        }
    }
    
    // 🛠️ تصميم شاشة الصيانة
    var maintenanceView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 25) {
                Image(systemName: "gearshape.2.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                Text("التطبيق تحت الصيانة")
                    .font(.largeTitle).bold()
                    .foregroundColor(.white)
                Text("نحن نقوم ببعض التحديثات السريعة، سنعود قريباً!")
                    .foregroundColor(.gray)
                    .font(.title3)
            }
        }
    }
    
    // ⬇️ تصميم شاشة التحديث الإجباري
    var updateView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 25) {
                Image(systemName: "arrow.down.app.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                Text("تحديث جديد متوفر!")
                    .font(.largeTitle).bold()
                    .foregroundColor(.white)
                Text("يرجى تحديث التطبيق للاستمرار في المشاهدة.")
                    .foregroundColor(.gray)
                    .font(.title3)
            }
        }
    }
}

// ==========================================
// 2. الواجهة الرئيسية وشريط الكبسولة المورف المطور فوق البوستر 🌟
// ==========================================
struct MainHomeView: View {
    @State private var selectedTab = "الرئيسية"
    let tabs = ["الرئيسية", "البحث", "التصنيفات", "التنزيلات", "اخرى"]
    
    // متغيرات التحكم المشتركة لربط كبسولة البحث الفوق بالشاشة الجوة تلقائياً
    @State private var globalSearchQuery = ""
    
    // 🌟 جلب مدير القياسات الذكي
    @StateObject private var layout = AppLayoutManager.shared
    
    var body: some View {
        ZStack(alignment: .top) { 
            
            // حاوية حفظ حالة الشاشات بالذاكرة ومنع تدمير البوسترات أو تصفير الـ Scroll
            ZStack {
                HomeView()
                    .opacity(selectedTab == "الرئيسية" ? 1 : 0)
                    .disabled(selectedTab != "الرئيسية")
                
                SearchView(searchQuery: $globalSearchQuery)
                    .padding(.top, 75)
                    .opacity(selectedTab == "البحث" ? 1 : 0)
                    .disabled(selectedTab != "البحث")
                
                CategoriesView()
                    .padding(.top, 75)
                    .opacity(selectedTab == "التصنيفات" ? 1 : 0)
                    .disabled(selectedTab != "التصنيفات")
                
                DownloadsView()
                    .padding(.top, 75)
                    .opacity(selectedTab == "التنزيلات" ? 1 : 0)
                    .disabled(selectedTab != "التنزيلات")
                
                OtherView()
                    .padding(.top, 75)
                    .opacity(selectedTab == "اخرى" ? 1 : 0)
                    .disabled(selectedTab != "اخرى")
            }
            
            // شريط التنقل الزجاجي الطائف (Floating Capsule) 
            HStack {
                if selectedTab == "البحث" {
                    // الكبسولة تتحول بالكامل لشريط بحث ذكي و ملموم
                    HStack(spacing: 12) {
                        Button(action: {
                            NotificationCenter.default.post(name: NSNotification.Name("TriggerSearchFetch"), object: nil)
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.blue)
                        }
                        
                        TextField("", text: $globalSearchQuery, prompt: Text("اكتب اسم الفيلم أو المسلسل...").foregroundColor(.gray.opacity(0.5)))
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .medium))
                            .multilineTextAlignment(.trailing)
                            .submitLabel(.search)
                            .onSubmit {
                                NotificationCenter.default.post(name: NSNotification.Name("TriggerSearchFetch"), object: nil)
                            }
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                globalSearchQuery = ""
                                selectedTab = "الرئيسية"
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    // 🌟 تمدد كبسولة البحث لتناسب الآيباد 
                    .frame(width: layout.isPad ? 500 : 360, height: layout.isPad ? 50 : 42) 
                } else {
                    HStack(spacing: layout.isPad ? 30 : 15) { // 🌟 تباعد أكبر بين الأزرار في الآيباد
                        ForEach(tabs, id: \.self) { tab in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = tab
                                }
                            }) {
                                Text(tab)
                                    .fixedSize()
                                // 🌟 تكبير خط الأزرار بالآيباد
                                    .font(.system(size: layout.isPad ? 17 : 14, weight: selectedTab == tab ? .bold : .medium))
                                    .foregroundColor(selectedTab == tab ? .blue : .gray.opacity(0.7))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedTab == tab ? Color.white.opacity(0.15) : Color.clear)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .environment(\.layoutDirection, .rightToLeft)
                    .padding(.horizontal, 20)
                    .padding(.vertical, layout.isPad ? 12 : 8) // 🌟 تكبير ارتفاع الكبسولة للآيباد
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            .padding(.top, layout.isPad ? 20 : 12) 
        }
        .background(Color.black.ignoresSafeArea())
    }
}

// ==========================================
// 3. شاشة البحث المتقدمة بالشغل الجبير والتصفية الحركية
// ==========================================
struct SearchView: View {
    @Binding var searchQuery: String
    @StateObject private var viewModel = MovieViewModel()
    
    // 🌟 جلب مدير القياسات الذكي
    @StateObject private var layout = AppLayoutManager.shared
    
    @State private var searchIsMovie = true
    @State private var searchSelectedSubGenre: SubGenreOption? = nil
    @State private var searchSelectedLanguage = LanguageOption(name: "الكل", code: "all")
    @State private var searchSelectedSort = SortOption(name: "المشاهدات", queryKey: "popularity.desc")
    @State private var selectedMovieToPlay: MovieItem? = nil
    
    let midnightNavy = Color(red: 0.03, green: 0.05, blue: 0.11)
    
    let subGenresList = [
        SubGenreOption(name: "اكشن", movieGenreId: 28, tvGenreId: 10759),
        SubGenreOption(name: "دراما", movieGenreId: 18, tvGenreId: 18),
        SubGenreOption(name: "كوميدي", movieGenreId: 35, tvGenreId: 35),
        SubGenreOption(name: "عائلي", movieGenreId: 10751, tvGenreId: 10762),
        SubGenreOption(name: "مغامرة", movieGenreId: 12, tvGenreId: 10759),
        SubGenreOption(name: "جريمة", movieGenreId: 80, tvGenreId: 80),
        SubGenreOption(name: "خيال علمي", movieGenreId: 878, tvGenreId: 10765),
        SubGenreOption(name: "رومانسي", movieGenreId: 10749, tvGenreId: 10766),
        SubGenreOption(name: "إثارة", movieGenreId: 53, tvGenreId: 9648),
        SubGenreOption(name: "فانتازيا", movieGenreId: 14, tvGenreId: 10765),
        SubGenreOption(name: "غموض", movieGenreId: 9648, tvGenreId: 9648),
        SubGenreOption(name: "حروب ", movieGenreId: 10752, tvGenreId: 10768),
        SubGenreOption(name: "تاريخي", movieGenreId: 36, tvGenreId: 18),
        SubGenreOption(name: "رعب", movieGenreId: 27, tvGenreId: 9648),
        SubGenreOption(name: "وثائقي", movieGenreId: 99, tvGenreId: 99)
    ]
    
    let searchLanguages = [
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
    
    let searchSortOptions = [
        SortOption(name: "المشاهدات", queryKey: "popularity.desc"),
        SortOption(name: "تاريخ الرفع", queryKey: "release_date.desc"),
        SortOption(name: "تصنيف الفئة", queryKey: "popularity.desc"),
        SortOption(name: "تقييم IMDB", queryKey: "vote_average.desc")
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // كبسولتين شفافة فقط إطار (أفلام / مسلسلات)
                HStack(spacing: 16) {
                    Button(action: {
                        if !searchIsMovie { searchIsMovie = true; triggerSearchCombined() }
                    }) {
                        Text("أفلام")
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundColor(searchIsMovie ? .blue : .gray)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(searchIsMovie ? Color.blue : Color.white.opacity(0.2), lineWidth: 1.5))
                    }
                    
                    Button(action: {
                        if searchIsMovie { searchIsMovie = false; triggerSearchCombined() }
                    }) {
                        Text("مسلسلات")
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundColor(!searchIsMovie ? .blue : .gray)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(!searchIsMovie ? Color.blue : Color.white.opacity(0.2), lineWidth: 1.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 15)
                
                // شريط الفلاتر المنسدلة المركزي
                HStack(spacing: 12) {
                    Spacer()
                    
                    Menu {
                        ForEach(searchLanguages, id: \.self) { lang in
                            Button(action: { searchSelectedLanguage = lang; triggerSearchCombined() }) {
                                HStack { Text(lang.name); if searchSelectedLanguage.code == lang.code { Image(systemName: "checkmark") } }
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold))
                            Text(searchSelectedLanguage.name).font(.system(size: 13, weight: .bold))
                        }
                        .padding(.horizontal, 18).padding(.vertical, 7)
                        .background(midnightNavy).foregroundColor(.white).clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    }
                    
                    Menu {
                        Button(action: { searchSelectedSubGenre = nil; triggerSearchCombined() }) {
                            HStack { Text("الكل"); if searchSelectedSubGenre == nil { Image(systemName: "checkmark") } }
                        }
                        ForEach(subGenresList, id: \.self) { genre in
                            Button(action: { searchSelectedSubGenre = genre; triggerSearchCombined() }) {
                                HStack { Text(genre.name); if searchSelectedSubGenre == genre { Image(systemName: "checkmark") } }
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold))
                            Text(searchSelectedSubGenre?.name ?? "التصنيف").font(.system(size: 13, weight: .bold))
                        }
                        .padding(.horizontal, 18).padding(.vertical, 7)
                        .background(midnightNavy).foregroundColor(.white).clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    }
                    
                    Menu {
                        ForEach(searchSortOptions, id: \.self) { option in
                            Button(action: { searchSelectedSort = option; triggerSearchCombined() }) {
                                HStack { Text(option.name); if searchSelectedSort.name == option.name { Image(systemName: "checkmark") } }
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.up.and.down.text.horizontal").font(.system(size: 10))
                            Text(searchSortOptions.first { $0.queryKey == searchSelectedSort.queryKey }?.name ?? searchSelectedSort.name).font(.system(size: 13, weight: .bold))
                            Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold))
                        }
                        .padding(.horizontal, 18).padding(.vertical, 7)
                        .background(midnightNavy).foregroundColor(.white).clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                
                // شبكة مخرجات البحث
                ScrollView {
                    if searchQuery.isEmpty {
                        VStack {
                            Image(systemName: "popcorn.fill")
                            // 🌟 تكبير الأيقونة للآيباد
                                .font(.system(size: layout.isPad ? 80 : 50))
                                .foregroundColor(.gray.opacity(0.3))
                                .padding(.top, 100)
                            Text("ابحث عن أي فيلم أو مسلسل فوق...")
                            // 🌟 تكبير الخط للآيباد
                                .font(.system(size: layout.isPad ? 18 : 14))
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                        }
                    } else if viewModel.searchItems.isEmpty {
                        Text("لا توجد نتائج تطابق الفلاتر المحددة")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .padding(.top, 100)
                    } else {
                        // 🌟 استخدام شبكة layout الذكية هنا
                        LazyVGrid(columns: layout.adaptiveGrid, spacing: 25) {
                            ForEach(viewModel.searchItems) { movie in
                                VStack {
                                    AsyncImage(url: movie.imageUrl) { img in img.resizable().scaledToFill() } placeholder: { RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.15)) }
                                    // 🌟 استخدام أحجام البوسترات من layout
                                        .frame(width: layout.posterWidth, height: layout.posterHeight).cornerRadius(12).clipped()
                                    
                                    Text(movie.displayName)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .multilineTextAlignment(.center)
                                    // 🌟 توسيع إطار النص ليطابق البوستر
                                        .frame(width: layout.posterWidth)
                                }
                                .onTapGesture {
                                    selectedMovieToPlay = movie
                                }
                            }
                        }
                        .padding()
                    }
                    Spacer().frame(height: 120)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .fullScreenCover(item: $selectedMovieToPlay) { movie in
            // الواجهة الخاصة بك لعرض التفاصيل
            DetailAndPlayerView(item: movie, allMovies: viewModel.searchItems) // قمت بتفعيلها لك
        }
        .onAppear {
            NotificationCenter.default.addObserver(forName: NSNotification.Name("TriggerSearchFetch"), object: nil, queue: .main) { _ in
                triggerSearchCombined()
            }
        }
        .onChange(of: searchQuery) {
            triggerSearchCombined()
        }
    }
    
    private func triggerSearchCombined() {
        let apiKey = "cf07279214de09093fc4874b6e2ad287"
        let genreId = searchIsMovie ? searchSelectedSubGenre?.movieGenreId : searchSelectedSubGenre?.tvGenreId
        
        viewModel.fetchSearchHybridContent(
            query: searchQuery,
            isMovie: searchIsMovie,
            genreId: genreId,
            langCode: searchSelectedLanguage.code,
            sortBy: searchSelectedSort.queryKey,
            apiKey: apiKey
        )
    }
}


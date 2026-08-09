import SwiftUI
import Combine

// هيكل للفئات الفرعية داخل صفحة أكثر
struct SubGenreOption: Hashable {
    let name: String
    let movieGenreId: Int
    let tvGenreId: Int
}

// ==========================================
// شريط الأخبار المتحرك (بتأثير كبسولة الدواء الذكية) 💊✨
// ==========================================
struct ScrollingBannerView: View {
    var text: String
    var isShowing: Bool
    
    @State private var stage: Int = 0
    @State private var offset: CGFloat = 1000
    @StateObject private var layout = AppLayoutManager.shared
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ZStack {
                    Color(red: 0.02, green: 0.03, blue: 0.15).opacity(0.85)
                    Color.clear.background(.ultraThinMaterial)
                }
                
                if stage == 3 {
                    Text(text)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.red)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(width: geo.size.width, alignment: .leading)
                        .offset(x: offset)
                        .transition(.opacity)
                        .onAppear {
                            offset = geo.size.width
                            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                                offset = -geo.size.width - 600
                            }
                        }
                }
            }
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
            .frame(width: stage >= 2 ? geo.size.width : 35, height: 35)
            .frame(maxWidth: .infinity, alignment: .center)
            .opacity(stage >= 1 ? 1 : 0)
        }
        .frame(height: stage > 0 ? 35 : 0) 
        .padding(.horizontal, 24)
        .padding(.vertical, stage > 0 ? 10 : 0)
        .onAppear {
            if isShowing { stage = 3 }
        }
        .onChange(of: isShowing) { oldValue, newValue in
            if newValue {
                withAnimation(.easeOut(duration: 0.3)) { stage = 1 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { stage = 2 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(.easeIn(duration: 0.3)) { stage = 3 }
                    }
                }
            } else {
                withAnimation(.easeOut(duration: 0.2)) { stage = 2 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { stage = 1 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(.easeOut(duration: 0.3)) { stage = 0 }
                    }
                }
            }
        }
    }
}

struct HomeView: View {
    let categories = ["الافلام", "المسلسلات", "الدراما التركية", "مدبلج عربي", "اسيوي", "انمي", "البرامج التلفزيونية", "كارتون", "مجموعات", "نجوم الشهر"]
    
    @StateObject private var viewModel = MovieViewModel()
    
    // 🌟 جلب مدير الإشعارات ومدير التخطيط
    @StateObject private var notificationManager = AppNotificationManager.shared
    @StateObject private var layout = AppLayoutManager.shared
    @State private var showNotificationsSheet = false
    
    @ObservedObject var config = AppConfig.shared
    
    @StateObject private var settings = AppConfigManager.shared
    
    @State private var currentPage = 0
    @State private var isMovingForward = true
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    @State private var selectedActor: ActorItem? = nil 
    @State private var isShowingActorDetails = false
    @State private var selectedCategoryForMore: String? = nil
    @State private var isShowingMorePage = false
    
    @State private var selectedMovieToPlay: MovieItem? = nil
    @State private var isShowingPlayer = false
    
    @State private var moreIsMovie = true
    @State private var moreSelectedSubGenre: SubGenreOption? = nil
    @State private var moreSelectedLanguage = LanguageOption(name: "الكل", code: "all")
    @State private var moreSelectedSort = SortOption(name: "المشاهدات", queryKey: "popularity.desc")
    
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
        SubGenreOption(name: "حروب", movieGenreId: 10752, tvGenreId: 10768),
        SubGenreOption(name: "تاريخي", movieGenreId: 36, tvGenreId: 18),
        SubGenreOption(name: "رعب", movieGenreId: 27, tvGenreId: 9648),
        SubGenreOption(name: "وثائقي", movieGenreId: 99, tvGenreId: 99)
    ]
    
    let moreLanguages = [
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
    
    let moreSortOptions = [
        SortOption(name: "المشاهدات", queryKey: "popularity.desc"),
        SortOption(name: "تاريخ الرفع", queryKey: "release_date.desc"),
        SortOption(name: "تصنيف الفئة", queryKey: "popularity.desc"),
        SortOption(name: "تقييم IMDB", queryKey: "vote_average.desc")
    ]
    
    func shouldShowCategory(_ category: String) -> Bool {
        switch category {
        case "الافلام": return settings.showMovies
        case "المسلسلات": return settings.showSeries
        case "الدراما التركية": return settings.showTurkish
        case "مدبلج عربي": return settings.showArabicDubbed
        case "اسيوي": return settings.showAsian
        case "انمي": return settings.showAnime
        case "البرامج التلفزيونية": return settings.showTVShows
        case "كارتون": return settings.showCartoon
        case "مجموعات": return settings.showCompanies
        case "نجوم الشهر": return settings.showStars
        default: return true
        }
    }
    
    func getMoviesForCategory(_ category: String) -> [MovieItem] {
        switch category {
        case "الافلام": return viewModel.movies
        case "المسلسلات": return viewModel.series
        case "الدراما التركية": return viewModel.turkishShows
        case "مدبلج عربي": return viewModel.arabicDubbed
        case "اسيوي": return viewModel.asianDubbed
        case "انمي": return viewModel.anime
        case "البرامج التلفزيونية": return viewModel.tvShows
        case "كارتون": return viewModel.cartoons
        default: return []
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isShowingMorePage, let categoryTitle = selectedCategoryForMore {
                allMoviesGridPage(title: categoryTitle)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) { 
                        
                        ZStack(alignment: .top) {
                            TabView(selection: $currentPage) {
                                if viewModel.carouselMovies.isEmpty {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.1))
                                        .overlay(ProgressView().tint(.white))
                                        .frame(height: 480)
                                        .tag(0)
                                } else {
                                    ForEach(Array(viewModel.carouselMovies.prefix(10).enumerated()), id: \.element.id) { index, movie in
                                        ZStack(alignment: .bottomLeading) {
                                            AsyncImage(url: movie.backdropUrl) { image in
                                                image.resizable().scaledToFill()
                                            } placeholder: {
                                                Rectangle().fill(Color.gray.opacity(0.2))
                                            }
                                            .frame(height: 480)
                                            .clipped()
                                            
                                            LinearGradient(gradient: Gradient(colors: [.black, .black.opacity(0.4), .clear]), startPoint: .bottom, endPoint: .top)
                                            
                                            Text(movie.displayName)
                                                .font(.system(size: 22, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 24)
                                                .padding(.bottom, 20)
                                        }
                                        .frame(height: 480)
                                        .tag(index)
                                        .onTapGesture { 
                                            selectedMovieToPlay = movie
                                            isShowingPlayer = true 
                                            AnalyticsManager.shared.logMovieClick(movieName: movie.displayName)
                                        }
                                    }
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                            .frame(height: 480)
                            
                            HStack {
                                Spacer()
                                Button(action: {
                                    showNotificationsSheet = true
                                    notificationManager.hasUnread = false 
                                }) {
                                    ZStack(alignment: .topTrailing) {
                                        Image(systemName: "bell.fill")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(10)
                                            .background(Color.black.opacity(0.35))
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
                                        
                                        if notificationManager.hasUnread {
                                            Circle()
                                                .fill(Color.red)
                                                .frame(width: 12, height: 12)
                                                .overlay(Circle().stroke(Color.black, lineWidth: 2))
                                                .offset(x: 2, y: -2)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            .zIndex(1)
                            .onReceive(timer) { _ in
                                let maxIndex = max(0, viewModel.carouselMovies.count - 1)
                                guard maxIndex > 0 else { return }
                                
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    if isMovingForward {
                                        if currentPage < maxIndex { currentPage += 1 } else { isMovingForward = false; currentPage -= 1 }
                                    } else {
                                        if currentPage > 0 { currentPage -= 1 } else { isMovingForward = true; currentPage += 1 }
                                    }
                                }
                            }
                            
                        }
                        
                        ScrollingBannerView(
                            text: config.bannerMessage, 
                            isShowing: config.showBanner && !config.bannerMessage.isEmpty
                        )
                        
                        LazyVStack(spacing: 30) {
                            Spacer().frame(height: 5)
                            
                            ForEach(categories, id: \.self) { cat in
                                if shouldShowCategory(cat) {
                                    if cat == "مجموعات" { companiesRow() }
                                    else if cat == "نجوم الشهر" { starsRow() }
                                    else { categoryRow(title: cat) }
                                }
                            }
                        }
                        Spacer().frame(height: 120)
                    }
                }
                .ignoresSafeArea(.container, edges: .top)
                .environment(\.layoutDirection, .rightToLeft)
            }
        }
        .fullScreenCover(isPresented: $showNotificationsSheet) {
            NotificationCenterView(notifications: notificationManager.notifications)
        }
        .sheet(isPresented: $isShowingActorDetails) {
            if let actor = selectedActor {
                ActorDetailView(actor: actor)
                    .presentationDetents([.fraction(0.75), .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .fullScreenCover(item: $selectedMovieToPlay) { movie in 
            DetailAndPlayerView(item: movie, allMovies: viewModel.movies)
        }
        .onAppear {
            let apiKey = "cf07279214de09093fc4874b6e2ad287"
            if viewModel.carouselMovies.isEmpty {
                viewModel.fetchCarouselMovies(apiKey: apiKey)
                viewModel.fetchPureMovies(apiKey: apiKey)
                viewModel.fetchPureSeries(apiKey: apiKey)
                viewModel.fetchTurkishShows(apiKey: apiKey)
                viewModel.fetchArabicDubbed(apiKey: apiKey)
                viewModel.fetchAsianDubbed(apiKey: apiKey)
                viewModel.fetchPureAnime(apiKey: apiKey)
                viewModel.fetchPureTVShows(apiKey: apiKey)
                viewModel.fetchPureCartoons(apiKey: apiKey)
                viewModel.fetchPopularStars(apiKey: apiKey)
            }
        }
    }
    
    @ViewBuilder
    func categoryRow(title: String) -> some View {
        let currentList = getMoviesForCategory(title)
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                Spacer()
                Button(action: { 
                    selectedCategoryForMore = title
                    moreIsMovie = (title == "الافلام" || title == "مدبلج عربي") ? true : false
                    moreSelectedSubGenre = nil
                    moreSelectedLanguage = LanguageOption(name: "الكل", code: "all")
                    moreSelectedSort = SortOption(name: "المشاهدات", queryKey: "popularity.desc")
                    
                    triggerMorePageFetch(categoryTitle: title)
                    isShowingMorePage = true 
                }) {
                    Text("المزيد")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(Color.clear)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.blue.opacity(0.5), lineWidth: 1.5)
                        )
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 15) {
                    ForEach(currentList.prefix(20)) { movie in 
                        AsyncImage(url: movie.imageUrl) { image in 
                            image.resizable().scaledToFill() 
                        } placeholder: { 
                            RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.2))
                        }
                        // تغيير الأبعاد هنا لاستخدام layout
                        .frame(width: layout.posterWidth, height: layout.posterHeight)
                        .cornerRadius(12).clipped()
                        .onTapGesture { 
                            selectedMovieToPlay = movie
                            isShowingPlayer = true 
                            AnalyticsManager.shared.logMovieClick(movieName: movie.displayName)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    @ViewBuilder
    func companiesRow() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("المجموعات").font(.system(size: 18, weight: .bold)).foregroundColor(.white).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 15) {
                    ForEach(viewModel.companies) { company in
                        ZStack {
                            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.2)).frame(width: 150, height: 90)
                            Text(company.displayName).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    @ViewBuilder
    func starsRow() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("نجوم الشهر").font(.system(size: 18, weight: .bold)).foregroundColor(.white).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 15) {
                    ForEach(viewModel.stars) { star in
                        Button(action: { selectedActor = star; isShowingActorDetails = true }) {
                            VStack(spacing: 8) {
                                AsyncImage(url: star.profileUrl) { img in 
                                    img.resizable().scaledToFill() 
                                } placeholder: { 
                                    Circle().fill(Color.gray.opacity(0.3))
                                }
                                .frame(width: 85, height: 85).clipShape(Circle())
                                
                                Text(star.name).font(.system(size: 12, weight: .medium)).foregroundColor(.white).lineLimit(1).frame(width: 90)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func triggerMorePageFetch(categoryTitle: String) {
        let apiKey = "cf07279214de09093fc4874b6e2ad287"
        let subGenreId = moreIsMovie ? moreSelectedSubGenre?.movieGenreId : moreSelectedSubGenre?.tvGenreId
        
        viewModel.fetchMorePageFilteredContent(
            mainCategory: categoryTitle,
            isMovie: moreIsMovie,
            subGenreId: subGenreId,
            langCode: moreSelectedLanguage.code,
            sortBy: moreSelectedSort.queryKey,
            apiKey: apiKey,
            loadNextPage: false
        )
    }
    
    @ViewBuilder
    func allMoviesGridPage(title: String) -> some View {
        let apiKey = "cf07279214de09093fc4874b6e2ad287"
        // استخدام adaptiveGrid من layout
        let columns = layout.adaptiveGrid
        
        VStack(spacing: 0) {
            HStack {
                Button(action: { isShowingMorePage = false }) {
                    HStack(spacing: 5) { Image(systemName: "chevron.right"); Text("رجوع") }.foregroundColor(.white).font(.system(size: 16, weight: .bold))
                }
                Spacer()
                Text(title).font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                Spacer()
            }
            .padding().background(Color.black)
            
            if title != "الافلام" && title != "المسلسلات" && title != "البرامج التلفزيونية" {
                HStack(spacing: 16) {
                    Button(action: {
                        if !moreIsMovie { moreIsMovie = true; triggerMorePageFetch(categoryTitle: title) }
                    }) {
                        Text("أفلام")
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundColor(moreIsMovie ? .blue : .gray)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(moreIsMovie ? Color.blue : Color.white.opacity(0.2), lineWidth: 1.5))
                    }
                    
                    Button(action: {
                        if moreIsMovie { moreIsMovie = false; triggerMorePageFetch(categoryTitle: title) }
                    }) {
                        Text("مسلسلات")
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundColor(!moreIsMovie ? .blue : .gray)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(!moreIsMovie ? Color.blue : Color.white.opacity(0.2), lineWidth: 1.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .padding(.bottom, 5)
            }
            
            HStack(spacing: 12) {
                Spacer()
                
                Menu {
                    ForEach(moreLanguages, id: \.self) { lang in
                        Button(action: { moreSelectedLanguage = lang; triggerMorePageFetch(categoryTitle: title) }) {
                            HStack { Text(lang.name); if moreSelectedLanguage.code == lang.code { Image(systemName: "checkmark") } }
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold))
                        Text(moreSelectedLanguage.name).font(.system(size: 13, weight: .bold))
                    }
                    .padding(.horizontal, 18).padding(.vertical, 7)
                    .background(midnightNavy).foregroundColor(.white).clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                
                Menu {
                    Button(action: { moreSelectedSubGenre = nil; triggerMorePageFetch(categoryTitle: title) }) {
                        HStack { Text("الكل"); if moreSelectedSubGenre == nil { Image(systemName: "checkmark") } }
                    }
                    ForEach(subGenresList, id: \.self) { genre in
                        Button(action: { moreSelectedSubGenre = genre; triggerMorePageFetch(categoryTitle: title) }) {
                            HStack { Text(genre.name); if moreSelectedSubGenre == genre { Image(systemName: "checkmark") } }
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold))
                        Text(moreSelectedSubGenre?.name ?? "التصنيف").font(.system(size: 13, weight: .bold))
                    }
                    .padding(.horizontal, 18).padding(.vertical, 7)
                    .background(midnightNavy).foregroundColor(.white).clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                
                Menu {
                    ForEach(moreSortOptions, id: \.self) { option in
                        Button(action: { moreSelectedSort = option; triggerMorePageFetch(categoryTitle: title) }) {
                            HStack { Text(option.name); if moreSelectedSort.name == option.name { Image(systemName: "checkmark") } }
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.up.and.down.text.horizontal").font(.system(size: 10))
                        Text(moreSelectedSort.name).font(.system(size: 13, weight: .bold))
                        Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 18).padding(.vertical, 7)
                    .background(midnightNavy).foregroundColor(.white).clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: config.showBanner)
            
            ScrollView {
                if viewModel.morePageItems.isEmpty {
                    VStack {
                        ProgressView().tint(.white).scaleEffect(1.2).padding(.top, 120)
                        Text("جاري تصفية وفرز البيانات حركياً...").font(.system(size: 12)).foregroundColor(.gray).padding(.top, 8)
                    }
                } else {
                    LazyVGrid(columns: columns, spacing: 25) {
                        ForEach(viewModel.morePageItems) { movie in
                            VStack {
                                AsyncImage(url: movie.imageUrl) { img in 
                                    img.resizable().scaledToFill() 
                                } placeholder: { 
                                    RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.2))
                                }
                                // تغيير الأبعاد هنا لاستخدام layout
                                .frame(width: layout.posterWidth, height: layout.posterHeight)
                                .cornerRadius(12).clipped()
                                Text(movie.displayName).font(.system(size: 13)).foregroundColor(.white).lineLimit(1)
                            }
                            .onTapGesture { selectedMovieToPlay = movie; isShowingPlayer = true }
                            .onAppear {
                                if movie.id == viewModel.morePageItems.last?.id {
                                    let subGenreId = moreIsMovie ? moreSelectedSubGenre?.movieGenreId : moreSelectedSubGenre?.tvGenreId
                                    viewModel.fetchMorePageFilteredContent(
                                        mainCategory: title,
                                        isMovie: moreIsMovie,
                                        subGenreId: subGenreId,
                                        langCode: moreSelectedLanguage.code,
                                        sortBy: moreSelectedSort.queryKey,
                                        apiKey: apiKey,
                                        loadNextPage: true
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                }
                Spacer().frame(height: 120)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}


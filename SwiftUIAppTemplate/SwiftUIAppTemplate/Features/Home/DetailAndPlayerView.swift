import SwiftUI
import WebKit

struct DetailAndPlayerView: View {
    let item: MovieItem
    let allMovies: [MovieItem] 
    @Environment(\.dismiss) var dismiss
    
    @State private var currentItem: MovieItem
    @ObservedObject private var downloadManager = DownloadManager.shared
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    @ObservedObject private var actionsManager = UserActionsManager.shared
    
    @State private var isOverviewExpanded = false 
    @State private var selectedSeason = 1 
    @State private var rotationDegree = 0.0 
    
    @State private var dynamicRuntime: String = "0:00"
    @State private var dynamicSeasons: Int = 1
    @State private var dynamicEpisodes: Int = 1
    @State private var dynamicViews: String = "0"
    @State private var fetchedIMDbID: String? = nil
    
    @State private var activeVideoItem: MovieItem? = nil
    
    init(item: MovieItem, allMovies: [MovieItem]) {
        self.item = item
        self.allMovies = allMovies
        self._currentItem = State(initialValue: item)
    }
    
    var filteredRelatedItems: [MovieItem] {
        allMovies.filter { $0.id != currentItem.id }.shuffled().prefix(10).map { $0 }
    }
    
    let midnightNavy = Color(red: 0.03, green: 0.05, blue: 0.11)
    let darkBluePlay = Color(red: 0.0, green: 0.22, blue: 0.65) 
    let premiumGold = Color(red: 1.0, green: 0.84, blue: 0.0) 
    
    var episodesInCurrentSeason: Int {
        let avg = dynamicEpisodes / max(1, dynamicSeasons)
        return max(1, avg)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) { 
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // 1. البوستر العلوي
                    ZStack(alignment: .bottom) {
                        AsyncImage(url: currentItem.backdropUrl ?? currentItem.imageUrl) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Rectangle().fill(Color.white.opacity(0.05))
                        }
                        .frame(height: 480) 
                        .clipped()
                        
                        LinearGradient(
                            gradient: Gradient(colors: [.black, .black.opacity(0.8), .black.opacity(0.3), .clear]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .frame(height: 250)
                        
                        HStack(spacing: 10) {
                            Text(currentItem.releaseDate ?? currentItem.firstAirDate ?? "2026")
                            Text("•")
                            Text(currentItem.displayGenres)
                            Text("•")
                            Text(dynamicRuntime) 
                        }
                        .font(.system(size: 11, weight: .bold)) 
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 25)
                        
                        VStack {
                            HStack(spacing: 12) {
                                Spacer()
                                
                                Text(currentItem.displayName)
                                    .font(.system(size: 22, weight: .black))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .multilineTextAlignment(.trailing)
                                
                                Button(action: { dismiss() }) {
                                    Image(systemName: "arrow.right.circle.fill") 
                                        .font(.system(size: 28))
                                        .foregroundColor(.white.opacity(0.9))
                                        .padding(4)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 50)
                            
                            Spacer()
                        }
                    }
                    .frame(height: 480)
                    
                    // 2. المحتوى السفلي
                    VStack(spacing: 20) {
                        
                        HStack(spacing: 40) {
                            Spacer()
                            
                            // زر المشاهدة لاحقاً (يمرر الفيلم كاملاً)
                            let isWL = actionsManager.isWatchLater(movie: currentItem)
                            Button(action: { 
                                actionsManager.toggleWatchLater(movie: currentItem)
                            }) {
                                VStack(spacing: 6) { 
                                    Image(systemName: isWL ? "checkmark.circle.fill" : "plus")
                                        .font(.system(size: 20))
                                        .foregroundColor(isWL ? .green : .white)
                                    Text("المشاهدة لاحقاً")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Button(action: { 
                                // هذا السطر هو اللي يضيف الفيلم لسجل المشاهدة فوراً عند الضغط
                                HistoryManager.shared.updateProgress(for: currentItem, progress: 0.35) // 0.35 يعني واصل 35% من العرض
                                
                                activeVideoItem = currentItem
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 14))
                                    Text("شاهد الآن")
                                        .font(.system(size: 15, weight: .bold))
                                }
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(midnightNavy)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.blue.opacity(0.3), lineWidth: 1))
                            }
                            
                            let movieID = "\(currentItem.id)"
                            let movieState = downloadManager.downloadingStates[movieID]
                            
                            Button(action: { 
                                if movieState == nil {
                                    downloadManager.startDownload(movie: currentItem, isMovie: true)
                                }
                            }) {
                                VStack(spacing: 6) {
                                    if movieState == "downloading" {
                                        Image(systemName: "clock.arrow.2.circlepath")
                                            .font(.system(size: 20))
                                            .foregroundColor(.blue)
                                            .rotationEffect(.degrees(rotationDegree))
                                            .onAppear {
                                                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                                    rotationDegree = 360
                                                }
                                            }
                                        Text("جاري حفظه...")
                                            .font(.system(size: 11, weight: .medium)).foregroundColor(.blue)
                                    } else if movieState == "completed" {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(premiumGold)
                                        Text("تم التنزيل")
                                            .font(.system(size: 11, weight: .bold)).foregroundColor(premiumGold)
                                    } else {
                                        Image(systemName: "arrow.down.to.line")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                        Text("تحميل")
                                            .font(.system(size: 11, weight: .medium)).foregroundColor(.gray)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 5)
                        
                        if let overview = currentItem.overview, !overview.isEmpty {
                            VStack(alignment: .trailing, spacing: 6) {
                                Text(overview)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.trailing)
                                    .lineSpacing(5)
                                    .lineLimit(isOverviewExpanded ? nil : 3) 
                                
                                if !isOverviewExpanded {
                                    Button(action: {
                                        withAnimation(.easeInOut) { isOverviewExpanded = true }
                                    }) {
                                        Text("المزيد...")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.top, 2)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        HStack {
                            Spacer()
                            HStack(spacing: 4) {
                                Text(dynamicViews)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white.opacity(0.9))
                                Text("مشاهدة")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, -5)
                        
                        // 🌟 أزرار التفاعل والمشاركة
                        HStack {
                            Spacer()
                            HStack(spacing: 15) {
                                
                                // 1. زر المشاركة
                                ShareLink(item: "شاهد معي \(currentItem.displayName) على تطبيق Iraq Cinema Box 🎬") {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white.opacity(0.6))
                                        .padding(10)
                                        .background(Color.white.opacity(0.05))
                                        .clipShape(Circle())
                                }
                                
                                // 2. زر الجرص
                                let isSub = actionsManager.isSubscribed(movie: currentItem)
                                Button(action: { actionsManager.toggleSubscribe(movie: currentItem) }) {
                                    Image(systemName: isSub ? "bell.badge.fill" : "bell")
                                        .font(.system(size: 18))
                                        .foregroundColor(isSub ? premiumGold : .white.opacity(0.6))
                                        .padding(10)
                                        .background(Color.white.opacity(0.05))
                                        .clipShape(Circle())
                                }
                                
                                // 3. زر المفضلة
                                let isFav = favoritesManager.isFavorite(movie: currentItem)
                                Button(action: {
                                    favoritesManager.toggleFavorite(movie: currentItem)
                                }) {
                                    Image(systemName: isFav ? "heart.fill" : "heart")
                                        .font(.system(size: 18))
                                        .foregroundColor(isFav ? .red : .white.opacity(0.6))
                                        .padding(10)
                                        .background(Color.white.opacity(0.05))
                                        .clipShape(Circle())
                                }
                                
                                // 4. زر الدسلايك
                                let isDis = actionsManager.isDisliked(id: currentItem.id)
                                Button(action: {
                                    actionsManager.setDisliked(movie: currentItem, status: !isDis)
                                }) {
                                    Image(systemName: isDis ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                        .font(.system(size: 18))
                                        .foregroundColor(isDis ? .red : .white.opacity(0.6))
                                        .padding(10)
                                        .background(Color.white.opacity(0.05))
                                        .clipShape(Circle())
                                }
                                
                                // 5. زر اللايك
                                let isLk = actionsManager.isLiked(movie: currentItem)
                                Button(action: {
                                    actionsManager.setLiked(movie: currentItem, status: !isLk)
                                }) {
                                    Image(systemName: isLk ? "hand.thumbsup.fill" : "hand.thumbsup")
                                        .font(.system(size: 18))
                                        .foregroundColor(isLk ? .blue : .white.opacity(0.6))
                                        .padding(10)
                                        .background(Color.white.opacity(0.05))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        if currentItem.releaseDate == nil || currentItem.firstAirDate != nil {
                            VStack(alignment: .trailing, spacing: 15) {
                                Text("الحلقات")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(1...dynamicSeasons, id: \.self) { seasonNumber in
                                            Button(action: { selectedSeason = seasonNumber }) {
                                                Text("موسم \(seasonNumber)")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(selectedSeason == seasonNumber ? .blue : .white.opacity(0.8))
                                                    .padding(.horizontal, 20)
                                                    .padding(.vertical, 8)
                                                    .background(Color.clear) 
                                                    .clipShape(Capsule())
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(selectedSeason == seasonNumber ? Color.blue : Color.white.opacity(0.3), lineWidth: 1.5)
                                                    )
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                                
                                VStack(spacing: 16) {
                                    ForEach(1...episodesInCurrentSeason, id: \.self) { episodeNumber in
                                        let epID = "\(currentItem.id)_S\(selectedSeason)_E\(episodeNumber)"
                                        let epState = downloadManager.downloadingStates[epID]
                                        
                                        HStack(spacing: 15) {
                                            Button(action: { 
                                                if epState == nil {
                                                    downloadManager.startDownload(movie: currentItem, isMovie: false, season: selectedSeason, episode: episodeNumber)
                                                }
                                            }) {
                                                if epState == "downloading" {
                                                    Image(systemName: "clock.arrow.2.circlepath")
                                                        .font(.system(size: 20))
                                                        .foregroundColor(.blue)
                                                        .rotationEffect(.degrees(rotationDegree))
                                                } else if epState == "completed" {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.system(size: 22))
                                                        .foregroundColor(premiumGold)
                                                } else {
                                                    Image(systemName: "arrow.down.circle")
                                                        .font(.system(size: 22))
                                                        .foregroundColor(.white.opacity(0.7))
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            VStack(alignment: .trailing, spacing: 4) {
                                                Text("الحلقة \(episodeNumber)")
                                                    .font(.system(size: 15, weight: .bold))
                                                    .foregroundColor(.white)
                                                Text("الموسم \(selectedSeason) • \(dynamicRuntime)")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Button(action: {
                                                let epTitle = "\(currentItem.displayName) - موسم \(selectedSeason) حلقة \(episodeNumber)"
                                                activeVideoItem = MovieItem(
                                                    id: currentItem.id,
                                                    title: epTitle,
                                                    name: "ep_\(selectedSeason)_\(episodeNumber)", 
                                                    posterPath: currentItem.posterPath,
                                                    backdropPath: currentItem.backdropPath,
                                                    overview: currentItem.overview,
                                                    voteAverage: currentItem.voteAverage,
                                                    releaseDate: currentItem.releaseDate,
                                                    firstAirDate: currentItem.firstAirDate,
                                                    genreIds: currentItem.genreIds
                                                )
                                            }) {
                                                ZStack {
                                                    AsyncImage(url: currentItem.imageUrl) { image in
                                                        image.resizable().scaledToFill()
                                                    } placeholder: {
                                                        RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08))
                                                    }
                                                    .frame(width: 135, height: 85) 
                                                    .cornerRadius(10)
                                                    .clipped()
                                                    
                                                    Color.black.opacity(0.15)
                                                        .cornerRadius(10)
                                                    
                                                    Image(systemName: "play.fill")
                                                        .font(.system(size: 20, weight: .bold))
                                                        .foregroundColor(darkBluePlay) 
                                                }
                                            }
                                            .frame(width: 135, height: 85)
                                        }
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 12)
                                        .background(Color.white.opacity(0.02)) 
                                        .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                            .environment(\.layoutDirection, .rightToLeft)
                        }
                        
                        Divider().background(Color.white.opacity(0.08)).padding(.horizontal, 24)
                        
                        VStack(alignment: .trailing, spacing: 15) {
                            Text("مقترحات تشبه هذا الفيلم")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(filteredRelatedItems) { related in
                                        Button(action: {
                                            withAnimation {
                                                currentItem = related
                                                isOverviewExpanded = false 
                                            }
                                        }) {
                                            VStack(alignment: .center, spacing: 8) {
                                                AsyncImage(url: related.imageUrl) { image in
                                                    image.resizable().scaledToFill()
                                                } placeholder: {
                                                    RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05))
                                                }
                                                .frame(width: 115, height: 170)
                                                .cornerRadius(16)
                                                .clipped()
                                                
                                                Text(related.displayName)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.white.opacity(0.9))
                                                    .lineLimit(1)
                                                    .frame(width: 115)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                    Spacer().frame(height: 120)
                }
            }
            
            if let toast = downloadManager.toastMessage {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(premiumGold)
                    Text(toast)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.85)) 
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                .padding(.bottom, 30) 
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .fullScreenCover(item: $activeVideoItem) { videoItem in
            StreamingWebViewPlayer(item: videoItem, imdbID: fetchedIMDbID)
        }
        .onAppear {
            fetchLiveMediaMetadata()
        }
        .onChange(of: currentItem) {
            fetchLiveMediaMetadata()
        }
    }
    
    private func fetchLiveMediaMetadata() {
        let apiKey = "cf07279214de09093fc4874b6e2ad287"
        let isMovie = currentItem.releaseDate != nil
        let endpoint = isMovie ? "movie" : "tv"
        
        let externalURLString = "https://api.themoviedb.org/3/\(endpoint)/\(currentItem.id)/external_ids?api_key=\(apiKey)"
        if let extURL = URL(string: externalURLString) {
            URLSession.shared.dataTask(with: extURL) { data, _, _ in
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let imdb = json["imdb_id"] as? String, !imdb.isEmpty {
                    DispatchQueue.main.async {
                        self.fetchedIMDbID = imdb
                    }
                }
            }.resume()
        }
        
        let urlString = "https://api.themoviedb.org/3/\(endpoint)/\(currentItem.id)?api_key=\(apiKey)&language=ar"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    let popularity = json?["popularity"] as? Double ?? 120.0
                    let realViews = Int(popularity * 145 + Double(currentItem.id % 500))
                    
                    DispatchQueue.main.async {
                        let formatter = NumberFormatter()
                        formatter.numberStyle = .decimal
                        self.dynamicViews = formatter.string(from: NSNumber(value: realViews)) ?? "\(realViews)"
                        
                        if isMovie {
                            let runtime = json?["runtime"] as? Int ?? 135
                            let hours = runtime / 60
                            let minutes = runtime % 60
                            self.dynamicRuntime = String(format: "%d:%02d", hours, minutes) 
                            self.dynamicSeasons = 1
                            self.dynamicEpisodes = 1
                        } else {
                            let seasons = json?["number_of_seasons"] as? Int ?? 1
                            let episodes = json?["number_of_episodes"] as? Int ?? 12
                            self.dynamicSeasons = max(1, seasons)
                            self.dynamicEpisodes = max(1, episodes)
                            
                            var epRuntime = 45
                            if let runTimes = json?["episode_run_time"] as? [Int], !runTimes.isEmpty {
                                epRuntime = runTimes[0]
                            }
                            let hours = epRuntime / 60
                            let minutes = epRuntime % 60
                            self.dynamicRuntime = String(format: "%d:%02d", hours, minutes) 
                        }
                    }
                } catch { print("Metadata processing error: \(error)") }
            }
        }.resume()
    }
}


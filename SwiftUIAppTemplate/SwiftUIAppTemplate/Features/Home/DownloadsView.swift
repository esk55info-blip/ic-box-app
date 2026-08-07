import SwiftUI

struct DownloadsView: View {
    @StateObject private var downloadManager = DownloadManager.shared
    
    // متغيرات للتحكم بفتح واجهة الحلقات الكاملة والمشغل الأصلي
    @State private var selectedMovieToPlay: MovieItem? = nil
    @State private var activeFullShowName: String? = nil // يتتبع المسلسل المفتوح واجهته الكاملة حالياً
    
    var downloadedMovies: [DownloadedItem] {
        downloadManager.downloadedItems.filter { $0.isMovie }
    }
    
    var downloadedSeriesGrouped: [String: [DownloadedItem]] {
        Dictionary(grouping: downloadManager.downloadedItems.filter { !$0.isMovie }) { $0.showTitle ?? "مسلسل" }
    }
    
    let midnightNavy = Color(red: 0.03, green: 0.05, blue: 0.11)
    
    // دالة ذكية لتهيئة المادة المحملة لتعمل بداخل مشغلك السينمائي الأصلي بكامل الشاشة
    func mapToMovieItem(from download: DownloadedItem) -> MovieItem {
        return MovieItem(
            id: download.movieId,
            title: download.isMovie ? download.title : download.showTitle,
            name: download.isMovie ? nil : download.showTitle,
            posterPath: download.posterPath,
            backdropPath: nil,
            overview: "هذا المحتوى محفوظ بالكامل داخل ذاكرة جهازك الآمنة، وجاهز للبث والتشغيل السينمائي الآن وبدون الحاجة لإنترنت.",
            voteAverage: 10.0,
            releaseDate: download.isMovie ? download.downloadDate : nil,
            firstAirDate: download.isMovie ? nil : download.downloadDate,
            genreIds: []
        )
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let showName = activeFullShowName {
                // 🌟 4. الواجهة الكاملة الممتدة لعرض الحلقات من الحلقة الأولى وتنازلياً
                fullEpisodesPage(showName: showName)
                    .transition(.move(edge: .leading)) // تأثير دخول حركي جانبي فخم
            } else {
                // الواجهة الرئيسية لجدول التنزيلات بمقاس الشاشة
                VStack(alignment: .trailing, spacing: 10) {
                    
                    // العناوين الرئيسية محاذاة لليمين تماماً
                    Text("خزانة التنزيلات الآمنة")
                        .font(.system(size: 26, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    if downloadManager.downloadedItems.isEmpty {
                        VStack(spacing: 15) {
                            Spacer()
                            Image(systemName: "square.and.arrow.down.on.square.dashed")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.3))
                            Text("الخزانة فارغة حالياً")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        // استخدام الـ List الافتراضي المطور لدعم حركات السحب البرمجية بسلاسة
                        List {
                            // 🎬 أولاً: خانة الأفلام (واحدة تلو الأخرى كمستطيلات مفرغة)
                            if !downloadedMovies.isEmpty {
                                Section(header: Text("الأفلام المحملة").font(.system(size: 14, weight: .bold)).foregroundColor(.blue).frame(maxWidth: .infinity, alignment: .trailing)) {
                                    ForEach(downloadedMovies) { item in
                                        movieRowView(item: item)
                                    }
                                }
                                .listResultFormatting()
                            }
                            
                            // 📺 ثانياً: خانة المسلسلات المجمعة تحت ألبوم وبوستر واحد
                            if !downloadedSeriesGrouped.isEmpty {
                                Section(header: Text("المسلسلات المحملة").font(.system(size: 14, weight: .bold)).foregroundColor(.blue).frame(maxWidth: .infinity, alignment: .trailing)) {
                                    ForEach(downloadedSeriesGrouped.keys.sorted(), id: \.self) { showName in
                                        let episodes = downloadedSeriesGrouped[showName] ?? []
                                        seriesRowView(showName: showName, episodes: episodes)
                                    }
                                }
                                .listResultFormatting()
                            }
                        }
                        .listStyle(.plain)
                        .background(Color.black)
                    }
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        // فتح واجهة المشغل السينمائي الكلي الأصلي مالتك بملء الشاشة فورا وبدون نت
        .fullScreenCover(item: $selectedMovieToPlay) { movie in
            DetailAndPlayerView(item: movie, allMovies: [movie])
        }
    }
    
    // 🎬 تصميم سطر الفيلم (مستطيل على شكل إطار فقط، البوستر يمين وزر التشغيل يسار)
    @ViewBuilder
    func movieRowView(item: DownloadedItem) -> some View {
        HStack(spacing: 15) {
            // زر التشغيل المثلث صار بأقصى اليسار
            Button(action: { 
                selectedMovieToPlay = mapToMovieItem(from: item)
            }) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // الاسم بالمنتصف محاذاة لليمين بصف البوستر وتحته التفاصيل الحجم
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text("فيلم كامل • \(item.fileSize)")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            
            // صورة الفيلم على اليمين تماماً بنصف الاسم
            localImageDisplay(path: item.localPosterPath)
                .frame(width: 55, height: 80)
                .cornerRadius(10)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Color.black) // خلفية سوداء نقية حته السحب يشتغل بنظافة
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.12), lineWidth: 1.5) // مستطيل على شكل إطار فقط 👍
        )
        // ميزة السحب البرمجية الفخمة من اليسار لليمين لإظهار زر الحذف
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(role: .destructive) {
                downloadManager.deleteDownload(id: item.id)
            } label: {
                Label("حذف", systemImage: "trash.fill")
            }
        }
    }
    
    // 📺 تصميم سطر المسلسل المجمع (مستطيل على شكل إطار، سهم باليسار وبوستر باليمين)
    @ViewBuilder
    func seriesRowView(showName: String, episodes: [DownloadedItem]) -> some View {
        let firstItem = episodes.first
        
        HStack(spacing: 15) {
            // سهم الانتقال بأقصى اليسار (chevron.left للاتجاه العربي للرجوع والأمام)
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    activeFullShowName = showName
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.gray.opacity(0.8))
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(showName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text("يحتوي على (\(episodes.count)) حلقات محملة")
                    .font(.system(size: 11))
                    .foregroundColor(.blue)
            }
            
            localImageDisplay(path: firstItem?.localPosterPath)
                .frame(width: 55, height: 80)
                .cornerRadius(10)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Color.black)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.12), lineWidth: 1.5) // مستطيل على شكل إطار فقط 👍
        )
        // عند سحب المسلسل بالكامل من اليسار يحذف المسلسل بكل حلقاته المندرجة جوة الذاكرة 🌟
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(role: .destructive) {
                for ep in episodes {
                    downloadManager.deleteDownload(id: ep.id)
                }
            } label: {
                Label("حذف الكل", systemImage: "trash.slope.fill")
            }
        }
    }
    
    // 🌟 4. الواجهة الكاملة الممتدة على كبر الشاشة لعرض حلقات المسلسل المختار بدقة وترتيب تصاعدي
    @ViewBuilder
    func fullEpisodesPage(showName: String) -> some View {
        // ترتيب الحلقات تصاعدياً من الحلقة الأولى ومابعدها (1, 2, 3...)
        let episodesList = (downloadedSeriesGrouped[showName] ?? []).sorted { 
            ($0.seasonNumber ?? 1, $0.episodeNumber ?? 1) < ($1.seasonNumber ?? 1, $1.episodeNumber ?? 1)
        }
        
        VStack(spacing: 0) {
            // شريط علوي كامل فخم للرجوع للواجهة الرئيسية للترتيب
            HStack {
                Button(action: {
                    withAnimation(.easeInOut) { activeFullShowName = nil }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.right")
                        Text("رجوع للخزينة")
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.blue)
                }
                Spacer()
                Text(showName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
            .background(Color.black.opacity(0.5))
            
            // قائمة عرض المستطيلات الفرعية لكل حلقة مفرغة وتدعم السحب للمفرد
            List {
                ForEach(episodesList) { item in
                    HStack {
                        // زر تشغيل الحلقة باليسار
                        Button(action: { 
                            selectedMovieToPlay = mapToMovieItem(from: item)
                        }) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("الموسم \(item.seasonNumber ?? 1) - الحلقة \(item.episodeNumber ?? 1)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Text("الحجم بذاكرة الآيباد: \(item.fileSize) • التنزيل: \(item.downloadDate)")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                        
                        localImageDisplay(path: item.localPosterPath)
                            .frame(width: 75, height: 50)
                            .cornerRadius(8)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.black)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    // سحب الحلقة المفردة بداخل القائمة الكاملة لحذفها هي فقط لتفريغ المساحة 👍
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            downloadManager.deleteDownload(id: item.id)
                            // إذا حذفت آخر حلقة بالمسلسل الواجهة ترجع تلقائياً للرئيسية حته ما تظل معلقة
                            if (downloadedSeriesGrouped[showName] ?? []).count <= 1 {
                                activeFullShowName = nil
                            }
                        } label: {
                            Label("حذف الحلقة", systemImage: "trash.fill")
                        }
                    }
                }
                .listRowBackground(Color.black)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .background(Color.black)
        }
    }
    
    @ViewBuilder
    func localImageDisplay(path: String?) -> some View {
        if let path = path, let uiImage = UIImage(contentsOfFile: path) {
            Image(uiImage: uiImage).resizable().scaledToFill()
        } else {
            RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08))
                .overlay(Image(systemName: "popcorn.fill").foregroundColor(.gray))
        }
    }
}

// Extension مساعد لتنسيق مظهر الـ List والـ Rows المفرغة بدقة عالية ومنع تداخل الحواف
extension View {
    func listResultFormatting() -> some View {
        self.listRowBackground(Color.black)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24))
    }
}


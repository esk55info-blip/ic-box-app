import SwiftUI
import WebKit

// ==========================================
// 🎬 المشغل السينمائي النهائي المتزامن (التحكم بالمشغل + الشريط العلوي)
// ==========================================
struct StreamingWebViewPlayer: View {
    let item: MovieItem
    let imdbID: String?
    @Environment(\.dismiss) var dismiss
    
    @State private var serverIndex: Int = 0
    @State private var availableURLs: [String] = []
    
    @State private var showControls = true
    @State private var showEpisodesDrawer = false
    @State private var showSettingsDrawer = false
    
    @State private var currentSeason: Int = 1
    @State private var currentEpisode: Int = 1
    
    // مؤقت الإخفاء التلقائي
    @State private var hideTimer: Task<Void, Never>? = nil
    
    var isMovie: Bool {
        item.releaseDate != nil
    }
    
    var currentServerURL: String {
        guard !availableURLs.isEmpty else { return "" }
        let idx = min(max(0, serverIndex), availableURLs.count - 1)
        return availableURLs[idx]
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // 1. عارض الويب المتزامن الذكي (يسمح بالضغط على أزرار الفلم + الشريط العلوي)
            if !currentServerURL.isEmpty {
                SimultaneousEmbedWebView(urlString: currentServerURL) {
                    handleScreenTap()
                }
                .id(currentServerURL)
                .ignoresSafeArea()
            }
            
            // 2. الشريط العلوي فقط (يظهر ويختفي، ولا يغطي الشاشة بالكامل)
            VStack {
                if showControls {
                    HStack(spacing: 15) {
                        
                        // زر الرجوع
                        Button(action: { dismiss() }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 34))
                                .foregroundColor(.white)
                                .padding(11)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        
                        // اسم الفيلم وتحته الموسم والحلقة
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.displayName)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            if !isMovie {
                                Text("الموسم \(currentSeason) • الحلقة \(currentEpisode)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.yellow.opacity(0.85))
                            } else {
                                Text("فيلم سينمائي")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        // زر إعدادات السيرفر وزر الحلقات
                        HStack(spacing: 10) {
                            Button(action: { showSettingsDrawer = true }) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(11)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            
                            if !isMovie {
                                Button(action: { showEpisodesDrawer = true }) {
                                    Image(systemName: "list.bullet.rectangle.portrait")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(11)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.black.opacity(0.85), .clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 110)
                        .ignoresSafeArea()
                    )
                    .transition(.opacity)
                }
                Spacer() // لجعل العناصر تتركز في الأعلى فقط ولا تمنع اللمس عن باقي الشاشة
            }
        }
        .onAppear {
            initializePlayer()
            startHideTimer()
        }
        .sheet(isPresented: $showEpisodesDrawer) {
            EpisodesDrawerSheet(
                currentSeason: $currentSeason,
                currentEpisode: $currentEpisode,
                item: item,
                onSelectEpisode: { season, ep in
                    currentSeason = season
                    currentEpisode = ep
                    serverIndex = 0
                    updateEpisodeSource(season: season, episode: ep)
                    showEpisodesDrawer = false
                    startHideTimer()
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSettingsDrawer) {
            ServerOnlySettingsSheet(
                serverIndex: $serverIndex,
                totalServers: availableURLs.count
            )
            .presentationDetents([.height(220)])
            .presentationDragIndicator(.visible)
        }
    }
    
    // دالة إظهار الشريط وإعادة ضبط المؤقت
    private func handleScreenTap() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showControls.toggle()
        }
        if showControls {
            startHideTimer()
        } else {
            hideTimer?.cancel()
        }
    }
    
    // دالة إخفاء الشريط بعد ثانيتين
    private func startHideTimer() {
        hideTimer?.cancel()
        hideTimer = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 ثانية
            if !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showControls = false
                }
            }
        }
    }
    
    private func initializePlayer() {
        if let payload = item.name, payload.hasPrefix("ep_") {
            let comps = payload.components(separatedBy: "_")
            if comps.count == 3 {
                currentSeason = Int(comps[1]) ?? 1
                currentEpisode = Int(comps[2]) ?? 1
            }
        }
        loadServerURLs(season: currentSeason, episode: currentEpisode)
    }
    
    private func loadServerURLs(season: Int, episode: Int) {
        availableURLs = MediaScraperManager.shared.getServerURLs(
            tmdbID: item.id,
            imdbID: imdbID,
            isMovie: isMovie,
            season: season,
            episode: episode
        )
    }
    
    private func updateEpisodeSource(season: Int, episode: Int) {
        loadServerURLs(season: season, episode: episode)
    }
}

// ==========================================
// 📋 درج الحلقات
// ==========================================
struct EpisodesDrawerSheet: View {
    @Binding var currentSeason: Int
    @Binding var currentEpisode: Int
    let item: MovieItem
    let onSelectEpisode: (Int, Int) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("اختر الحلقات")) {
                    ForEach(1...15, id: \.self) { epNum in
                        HStack {
                            Text("الحلقة \(epNum)")
                                .fontWeight(currentEpisode == epNum ? .bold : .regular)
                                .foregroundColor(currentEpisode == epNum ? .blue : .white)
                            Spacer()
                            if currentEpisode == epNum {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelectEpisode(currentSeason, epNum)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("قائمة الحلقات")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("إغلاق") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// ==========================================
// ⚙️ إعدادات السيرفر
// ==========================================
struct ServerOnlySettingsSheet: View {
    @Binding var serverIndex: Int
    let totalServers: Int
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("تبديل السيرفر الاحتياطي")) {
                    Picker("السيرفر النشط", selection: $serverIndex) {
                        ForEach(0..<max(1, totalServers), id: \.self) { idx in
                            Text("السيرفر رقم \(idx + 1)").tag(idx)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("إعدادات السيرفر")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("تم") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// ==========================================
// 🌐 عارض الويب المتزامن الذكي (النسخة الصافية والمستقرة)
// ==========================================
struct SimultaneousEmbedWebView: UIViewRepresentable {
    let urlString: String
    let onTap: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.customUserAgent = "Mozilla/5.0 (iPad; CPU OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1"
        
        // منع الشاشة من الانطفاء أثناء المشاهدة
        UIApplication.shared.isIdleTimerDisabled = true
        
        // إنشاء ملقط لمسات ذكي
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = context.coordinator
        webView.addGestureRecognizer(tapGesture)
        
        if let url = URL(string: urlString) {
            var request = URLRequest(url: url)
            request.setValue("https://google.com", forHTTPHeaderField: "Referer")
            webView.load(request)
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let onTap: () -> Void
        
        init(onTap: @escaping () -> Void) {
            self.onTap = onTap
        }
        
        @objc func handleTap() {
            onTap()
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true 
        }
    }
}


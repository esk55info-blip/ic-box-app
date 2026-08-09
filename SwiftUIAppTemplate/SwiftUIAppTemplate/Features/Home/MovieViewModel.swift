import Foundation
import SwiftUI
import Combine

// MARK: - Models
struct MovieResponse: Codable {
    let results: [MovieItem]
}

struct MovieItem: Codable, Identifiable, Hashable {
    let id: Int
    let title: String?
    let name: String?
    let posterPath: String?
    let backdropPath: String?
    let overview: String?
    let voteAverage: Double?
    let releaseDate: String?
    let firstAirDate: String?
    let genreIds: [Int]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, name, overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case genreIds = "genre_ids"
    }
    
    var displayName: String {
        return title ?? name ?? "عنوان غير معروف"
    }
    
    var displayTitle: String { return displayName }
    
    var imageUrl: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w342\(path)")
    }
    var imageURL: URL? { return imageUrl }
    
    var backdropUrl: URL? {
        guard let path = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/original\(path)")
    }
    var backdropURL: URL? { return backdropUrl }
    
    var displayGenres: String {
        guard let ids = genreIds, !ids.isEmpty else { return "عام" }
        let genreMap: [Int: String] = [
            28: "أكشن", 12: "مغامرة", 16: "أنمي وكارتون", 35: "كوميديا",
            80: "جريمة", 99: "وثائقي", 18: "دراما", 10751: "عائلي",
            14: "خيالي", 36: "تاريخي", 27: "رعب", 10402: "موسيقى",
            9648: "غموض", 10749: "رومانسي", 878: "خيال علمي",
            53: "إثارة", 10752: "حروب", 10759: "أكشن ومغامرة",
            10762: "أطفال", 10765: "خيال علمي ", 10768: "حرب "
        ]
        let names = ids.compactMap { genreMap[$0] }.prefix(3)
        return names.isEmpty ? "منوع" : names.joined(separator: " • ")
    }
}

struct ActorItem: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let profilePath: String?
    let popularity: Double?
    let knownFor: [MovieItem]? 
    
    enum CodingKeys: String, CodingKey {
        case id, name, popularity
        case profilePath = "profile_path"
        case knownFor = "known_for"
    }
    
    var profileUrl: URL? {
        guard let path = profilePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }
    var profileURL: URL? { return profileUrl }
}

// MARK: - ViewModel
class MovieViewModel: ObservableObject {
    @Published var carouselMovies: [MovieItem] = []
    @Published var movies: [MovieItem] = []
    @Published var series: [MovieItem] = []
    @Published var turkishShows: [MovieItem] = []
    @Published var arabicDubbed: [MovieItem] = []
    @Published var asianDubbed: [MovieItem] = []
    @Published var anime: [MovieItem] = []
    @Published var tvShows: [MovieItem] = []
    @Published var cartoons: [MovieItem] = []
    @Published var stars: [ActorItem] = []
    @Published var companies: [MovieItem] = [] 
    
    @Published var categoryItems: [MovieItem] = []
    var categoryCurrentPage = 1
    
    @Published var morePageItems: [MovieItem] = []
    var moreCurrentPage = 1
    
    @Published var searchItems: [MovieItem] = []
    
    var moviesPage = 1
    var seriesPage = 1
    var turkishPage = 1
    var arabicPage = 1
    var asianPage = 1
    var animePage = 1
    var tvPage = 1
    var cartoonsPage = 1
    
    init() {}
    
    // 🌟 1. دالة فحص اللغات المقبولة (عربي، إنجليزي، تركي وأرقام فقط)
    private func isValidLanguageTitle(_ text: String) -> Bool {
        let allowedPattern = "^[\\s\\d\\p{Latin}\\p{Arabic}\\p{Punctuation}]+$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", allowedPattern)
        return predicate.evaluate(with: text)
    }
    
    // 🌟 2. دالة الفحص المسبق عبر المحرك الثلاثي: استبعاد أي بوستر ليس له فيديو في السيرفرات الثلاثة
    // 🌟 دالة الفحص المسبق عبر المحرك الثلاثي
    private func filterAvailableItems(_ items: [MovieItem], completion: @escaping ([MovieItem]) -> Void) {
        Task {
            var validItems: [MovieItem] = []
            
            await withTaskGroup(of: (MovieItem, Bool).self) { group in
                for item in items {
                    group.addTask {
                        let isMovie = item.releaseDate != nil
                        let isAvailable = await MediaScraperManager.shared.isAvailableOnAnyServer(tmdbID: item.id, isMovie: isMovie)
                        return (item, isAvailable)
                    }
                }
                
                for await (item, isAvailable) in group {
                    if isAvailable {
                        validItems.append(item)
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion(validItems)
            }
        }
    }
    
    // 🌟 3. دالة جلب من TMDB مع الفلترة المزدوجة (لغة + توفر البث بالسيرفرات)
    private func fetchFromTMDB(endpoint: String, urlParams: String = "", apiKey: String, page: Int, completion: @escaping ([MovieItem]) -> Void) {
        let safeParams = "\(urlParams)&primary_release_date.lte=2026-07-22&vote_count.gte=10"
        let urlString = "https://api.themoviedb.org/3/\(endpoint)?api_key=\(apiKey)&language=ar&page=\(page)\(safeParams)"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(MovieResponse.self, from: data)
                    
                    // أ. تصفية العناوين غير المفهومة وتأكيد وجود بوستر
                    let cleanResults = decodedResponse.results.filter { item in
                        self.isValidLanguageTitle(item.displayName) && item.posterPath != nil
                    }
                    
                    // ب. الفحص المسبق: استبعاد أي فيلم ليس له فيديو في أي من المشغلات الثلاثة
                    self.filterAvailableItems(cleanResults) { availableResults in
                        completion(availableResults)
                    }
                } catch { print("Error decoding: \(error)") }
            }
        }
        .resume()
    }
    
    func fetchCarouselMovies(apiKey: String) {
        fetchFromTMDB(endpoint: "trending/all/day", apiKey: apiKey, page: 1) { (results: [MovieItem]) in
            self.carouselMovies = Array(results.prefix(10))
        }
    }
    
    func fetchPureMovies(apiKey: String, loadNextPage: Bool = false) {
        if loadNextPage { moviesPage += 1 }
        fetchFromTMDB(endpoint: "discover/movie", urlParams: "&sort_by=popularity.desc&without_genres=16&without_original_language=ar", apiKey: apiKey, page: moviesPage) { (results: [MovieItem]) in
            if loadNextPage { self.movies.append(contentsOf: results) } else { self.movies = results }
        }
    }
    
    func fetchPureSeries(apiKey: String, loadNextPage: Bool = false) {
        if loadNextPage { seriesPage += 1 }
        fetchFromTMDB(endpoint: "discover/tv", urlParams: "&sort_by=popularity.desc&without_genres=16&without_original_language=tr|ar|ko|ja|zh", apiKey: apiKey, page: seriesPage) { (results: [MovieItem]) in
            if loadNextPage { self.series.append(contentsOf: results) } else { self.series = results }
        }
    }
    
    func fetchTurkishShows(apiKey: String, loadNextPage: Bool = false) {
        if loadNextPage { turkishPage += 1 }
        fetchFromTMDB(endpoint: "discover/tv", urlParams: "&with_original_language=tr&sort_by=popularity.desc", apiKey: apiKey, page: turkishPage) { (tvResults: [MovieItem]) in
            if loadNextPage { self.turkishShows.append(contentsOf: tvResults) } else { self.turkishShows = tvResults }
        }
    }
    
    func fetchArabicDubbed(apiKey: String, loadNextPage: Bool = false) {
        if loadNextPage { arabicPage += 1 }
        fetchFromTMDB(endpoint: "discover/tv", urlParams: "&with_original_language=ar&sort_by=popularity.desc", apiKey: apiKey, page: arabicPage) { (results: [MovieItem]) in
            if loadNextPage { self.arabicDubbed.append(contentsOf: results) } else { self.arabicDubbed = results }
        }
    }
    
    func fetchAsianDubbed(apiKey: String, loadNextPage: Bool = false) {
        if loadNextPage { asianPage += 1 }
        fetchFromTMDB(endpoint: "discover/tv", urlParams: "&with_original_language=ko|ja|zh&sort_by=popularity.desc", apiKey: apiKey, page: asianPage) { (results: [MovieItem]) in
            if loadNextPage { self.asianDubbed.append(contentsOf: results) } else { self.asianDubbed = results }
        }
    }
    
    func fetchPureAnime(apiKey: String, loadNextPage: Bool = false) {
        if loadNextPage { animePage += 1 }
        fetchFromTMDB(endpoint: "discover/tv", urlParams: "&with_genres=16&with_original_language=ja&sort_by=popularity.desc", apiKey: apiKey, page: animePage) { (results: [MovieItem]) in
            if loadNextPage { self.anime.append(contentsOf: results) } else { self.anime = results }
        }
    }
    
    func fetchPureTVShows(apiKey: String, loadNextPage: Bool = false) {
        if loadNextPage { tvPage += 1 }
        fetchFromTMDB(endpoint: "discover/tv", urlParams: "&with_genres=10767|10764&sort_by=popularity.desc", apiKey: apiKey, page: tvPage) { (results: [MovieItem]) in
            if loadNextPage { self.tvShows.append(contentsOf: results) } else { self.tvShows = results }
        }
    }
    
    func fetchPureCartoons(apiKey: String, loadNextPage: Bool = false) {
        if loadNextPage { cartoonsPage += 1 }
        fetchFromTMDB(endpoint: "discover/tv", urlParams: "&with_genres=16&without_original_language=ja&sort_by=popularity.desc", apiKey: apiKey, page: cartoonsPage) { (results: [MovieItem]) in
            if loadNextPage { self.cartoons.append(contentsOf: results) } else { self.cartoons = results }
        }
    }
    
    // 🌟 4. نجوم الشهر المفلترة لضمان عدم إظهار ممثلين بأسماء غير عربية/إنجليزية/تركية
    func fetchPopularStars(apiKey: String) {
        var temporaryStars: [ActorItem] = []
        let group = DispatchGroup()
        
        let targetMedia = [
            "movie/533535",
            "tv/71914",
            "tv/37854",
            "movie/1022789"
        ]
        
        for media in targetMedia {
            group.enter()
            let urlString = "https://api.themoviedb.org/3/\(media)/credits?api_key=\(apiKey)&language=ar"
            guard let url = URL(string: urlString) else { group.leave(); continue }
            
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data {
                    do {
                        struct CreditsResponse: Codable { let cast: [ActorItem] }
                        let decodedResponse = try JSONDecoder().decode(CreditsResponse.self, from: data)
                        
                        let validCast = decodedResponse.cast.filter { actor in
                            self.isValidLanguageTitle(actor.name) && actor.profilePath != nil
                        }
                        
                        let mainCast = Array(validCast.prefix(3))
                        
                        DispatchQueue.main.async {
                            temporaryStars.append(contentsOf: mainCast)
                        }
                    } catch { print("Error decoding cast for \(media): \(error)") }
                }
                group.leave()
            }.resume()
        }
        
        group.notify(queue: .main) {
            self.stars = temporaryStars.shuffled()
        }
    }
    
    func fetchCategoryContent(isMovie: Bool, genreParams: String, langCode: String, sortBy: String, apiKey: String, loadNextPage: Bool = false) {
        if loadNextPage { categoryCurrentPage += 1 } else { categoryCurrentPage = 1 }
        let endpoint = isMovie ? "discover/movie" : "discover/tv"
        var urlParams = "\(genreParams)"
        if langCode != "all" { urlParams += "&with_original_language=\(langCode)" }
        var finalSortBy = sortBy
        if !isMovie && sortBy == "release_date.desc" { finalSortBy = "first_air_date.desc" }
        urlParams += "&sort_by=\(finalSortBy)"
        
        fetchFromTMDB(endpoint: endpoint, urlParams: urlParams, apiKey: apiKey, page: categoryCurrentPage) { (results: [MovieItem]) in
            if loadNextPage { self.categoryItems.append(contentsOf: results) } else { self.categoryItems = results }
        }
    }
    
    func fetchMorePageFilteredContent(mainCategory: String, isMovie: Bool, subGenreId: Int?, langCode: String, sortBy: String, apiKey: String, loadNextPage: Bool = false) {
        if loadNextPage { moreCurrentPage += 1 } else { moreCurrentPage = 1 }
        let endpoint = isMovie ? "discover/movie" : "discover/tv"
        var params = ""
        
        switch mainCategory {
        case "الافلام":
            params += "&without_genres=16&without_original_language=ar"
        case "المسلسلات":
            params += "&without_genres=16&without_original_language=tr|ar|ko|ja|zh"
        case "الدراما التركية": 
            params += "&with_original_language=tr"
        case "مدبلج عربي": 
            params += "&with_original_language=ar"
        case "اسيوي": 
            params += "&with_original_language=ko|ja|zh"
        case "انمي": 
            params += "&with_genres=16&with_original_language=ja"
        case "البرامج التلفزيونية": 
            params += "&with_genres=10767|10764"
        case "كارتون": 
            params += "&with_genres=16&without_original_language=ja"
        default: 
            break
        }
        
        if let subId = subGenreId { params += "&with_genres=\(subId)" }
        if langCode != "all" { params += "&with_original_language=\(langCode)" }
        var finalSort = sortBy
        if !isMovie && sortBy == "release_date.desc" { finalSort = "first_air_date.desc" }
        params += "&sort_by=\(finalSort)"
        
        fetchFromTMDB(endpoint: endpoint, urlParams: params, apiKey: apiKey, page: moreCurrentPage) { (results: [MovieItem]) in
            if loadNextPage { self.morePageItems.append(contentsOf: results) } else { self.morePageItems = results }
        }
    }
    
    func fetchSearchHybridContent(query: String, isMovie: Bool, genreId: Int?, langCode: String, sortBy: String, apiKey: String) {
        if query.isEmpty {
            DispatchQueue.main.async { self.searchItems = [] }
            return
        }
        
        let endpoint = isMovie ? "search/movie" : "search/tv"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlParams = "&query=\(encodedQuery)"
        
        let urlString = "https://api.themoviedb.org/3/\(endpoint)?api_key=\(apiKey)&language=ar&page=1\(urlParams)"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(MovieResponse.self, from: data)
                    var results = decodedResponse.results
                    
                    results = results.filter { item in
                        self.isValidLanguageTitle(item.displayName) && item.posterPath != nil
                    }
                    
                    if let gId = genreId {
                        results = results.filter { $0.genreIds?.contains(gId) == true }
                    }
                    if sortBy.contains("vote_average") {
                        results.sort { ($0.voteAverage ?? 0) > ($1.voteAverage ?? 0) }
                    } else if sortBy.contains("release_date") {
                        results.sort { ($0.releaseDate ?? $0.firstAirDate ?? "") > ($1.releaseDate ?? $1.firstAirDate ?? "") }
                    }
                    
                    self.filterAvailableItems(results) { validSearchResults in
                        self.searchItems = validSearchResults
                    }
                } catch { print("Search processing error: \(error)") }
            }
        }
        .resume()
    }
}

struct ActorResponse: Codable {
    let results: [ActorItem]
}

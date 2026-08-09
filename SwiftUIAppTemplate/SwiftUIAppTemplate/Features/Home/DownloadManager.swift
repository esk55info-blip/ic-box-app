import Foundation
import SwiftUI
import Combine

struct DownloadedItem: Codable, Identifiable, Hashable {
    let id: String
    let movieId: Int
    let title: String
    let posterPath: String?
    let localPosterPath: String?
    let isMovie: Bool
    let showTitle: String?
    let seasonNumber: Int?
    let episodeNumber: Int?
    let fileSize: String
    let downloadDate: String
}

class DownloadManager: ObservableObject {
    static let shared = DownloadManager()
    
    @Published var downloadedItems: [DownloadedItem] = []
    @Published var downloadingStates: [String: String] = [:]
    @Published var toastMessage: String? = nil
    
    private let fileManager = FileManager.default
    
    init() {
        loadDownloadsDatabase()
    }
    
    private var documentsDirectory: URL {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var databaseURL: URL {
        return documentsDirectory.appendingPathComponent("downloads_secure_db.json")
    }
    
    func startDownload(movie: MovieItem, isMovie: Bool, season: Int? = nil, episode: Int? = nil) {
        let downloadID = isMovie ? "\(movie.id)" : "\(movie.id)_S\(season ?? 1)_E\(episode ?? 1)"
        
        if downloadedItems.contains(where: { $0.id == downloadID }) {
            return
        }
        
        DispatchQueue.main.async {
            self.downloadingStates[downloadID] = "downloading"
        }
        
        let simulatedSizeInBytes = isMovie ? 185 * 1024 * 1024 : 48 * 1024 * 1024
        let sizeString = isMovie ? "185 MB" : "48 MB"
        
        DispatchQueue.global(qos: .background).async {
            Thread.sleep(forTimeInterval: 2.5) 
            
            let secureFolder = self.documentsDirectory.appendingPathComponent("Secure_Media_Box", isDirectory: true)
            if !self.fileManager.fileExists(atPath: secureFolder.path) {
                try? self.fileManager.createDirectory(at: secureFolder, withIntermediateDirectories: true, attributes: nil)
            }
            
            let videoFileURL = secureFolder.appendingPathComponent("\(downloadID).dat")
            let dummyData = Data(count: simulatedSizeInBytes)
            try? dummyData.write(to: videoFileURL)
            
            var localPosterURLString: String? = nil
            if let posterPath = movie.posterPath,
               let posterURL = URL(string: "https://image.tmdb.org/t/p/w342\(posterPath)"),
               let posterData = try? Data(contentsOf: posterURL) {
                let localPosterURL = secureFolder.appendingPathComponent("\(downloadID)_poster.jpg")
                try? posterData.write(to: localPosterURL)
                localPosterURLString = localPosterURL.path
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            let dateStr = formatter.string(from: Date())
            
            let itemTitle = isMovie ? movie.displayName : "Season \(season ?? 1) - Episode \(episode ?? 1)"
            
            let newItem = DownloadedItem(
                id: downloadID,
                movieId: movie.id,
                title: itemTitle,
                posterPath: movie.posterPath,
                localPosterPath: localPosterURLString,
                isMovie: isMovie,
                showTitle: isMovie ? nil : movie.displayName,
                seasonNumber: season,
                episodeNumber: episode,
                fileSize: sizeString,
                downloadDate: dateStr
            )
            
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.downloadedItems.append(newItem)
                    self.downloadingStates[downloadID] = "completed"
                    
                    let displayNotificationName = isMovie ? movie.displayName : "\(movie.displayName) (\(itemTitle))"
                    self.toastMessage = "Download completed for \(displayNotificationName)"
                    self.saveDownloadsDatabase()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation { self.toastMessage = nil }
                }
            }
        }
    }
    
    func deleteDownload(id: String) {
        withAnimation(.spring()) {
            downloadedItems.removeAll { item in
                if item.id == id {
                    let secureFolder = self.documentsDirectory.appendingPathComponent("Secure_Media_Box")
                    try? fileManager.removeItem(at: secureFolder.appendingPathComponent("\(id).dat"))
                    try? fileManager.removeItem(at: secureFolder.appendingPathComponent("\(id)_poster.jpg"))
                    return true
                }
                return false
            }
            downloadingStates[id] = nil
            saveDownloadsDatabase()
        }
    }
    
    private func saveDownloadsDatabase() {
        if let data = try? JSONEncoder().encode(downloadedItems) {
            try? data.write(to: databaseURL)
        }
    }
    
    private func loadDownloadsDatabase() {
        if let data = try? Data(contentsOf: databaseURL),
           let items = try? JSONDecoder().decode([DownloadedItem].self, from: data) {
            self.downloadedItems = items
            for item in items {
                self.downloadingStates[item.id] = "completed"
            }
        }
    }
}

import SwiftUI

struct ActorDetailView: View {
    let actor: ActorItem
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedMovieToPlay: MovieItem? = nil
    @State private var actorMovies: [MovieItem] = []
    @State private var isLoading = true
    
    private func isValidLanguageTitle(_ text: String) -> Bool {
        let allowedPattern = "^[\\s\\d\\p{Latin}\\p{Arabic}\\p{Punctuation}]+$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", allowedPattern)
        return predicate.evaluate(with: text)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        AsyncImage(url: actor.profileUrl) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Circle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 130, height: 130)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 2))
                        .padding(.top, 20)
                        
                        Text(actor.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Divider().background(Color.white.opacity(0.15))
                        
                        VStack(alignment: .trailing, spacing: 15) {
                            Text("أبرز الأعمال المتوفرة")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(1.2)
                                    .padding(.top, 40)
                            } else if !actorMovies.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(actorMovies) { movie in
                                            VStack(alignment: .center, spacing: 8) {
                                                AsyncImage(url: movie.imageUrl) { image in
                                                    image.resizable().scaledToFill()
                                                } placeholder: {
                                                    RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08))
                                                }
                                                .frame(width: 115, height: 165)
                                                .cornerRadius(12)
                                                .clipped()
                                                
                                                Text(movie.displayName)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.white.opacity(0.9))
                                                    .lineLimit(1)
                                                    .frame(width: 115)
                                            }
                                            .onTapGesture {
                                                selectedMovieToPlay = movie
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                            } else {
                                Text("لا توجد أعمال متوفرة حالياً")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 24)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        
                        Spacer().frame(height: 50)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("إغلاق") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .fullScreenCover(item: $selectedMovieToPlay) { movie in
            DetailAndPlayerView(item: movie, allMovies: actorMovies)
        }
        .onAppear {
            fetchActorCombinedCredits()
        }
    }
    
    private func fetchActorCombinedCredits() {
        let apiKey = "cf07279214de09093fc4874b6e2ad287"
        let urlString = "https://api.themoviedb.org/3/person/\(actor.id)/combined_credits?api_key=\(apiKey)&language=ar"
        
        guard let url = URL(string: urlString) else {
            self.isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                do {
                    struct ActorCreditsResponse: Codable { let cast: [MovieItem] }
                    let decodedResponse = try JSONDecoder().decode(ActorCreditsResponse.self, from: data)
                    
                    let filteredMedia = decodedResponse.cast
                        .filter { $0.posterPath != nil && self.isValidLanguageTitle($0.displayName) }
                        .sorted { ($0.voteAverage ?? 0) > ($1.voteAverage ?? 0) }
                    
                    DispatchQueue.main.async {
                        self.actorMovies = Array(filteredMedia.prefix(15))
                        self.isLoading = false
                    }
                } catch {
                    print("Error decoding actor combined credits: \(error)")
                    DispatchQueue.main.async { self.isLoading = false }
                }
            } else {
                DispatchQueue.main.async { self.isLoading = false }
            }
        }.resume()
    }
}

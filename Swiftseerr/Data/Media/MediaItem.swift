// Made by Lumaa

import Foundation

struct MediaItem: Identifiable {
    let id: Int
    let type: ItemType

    let title: String
    let tagline: String
    let overview: String

    var requestStatus: MediaStatus
    var requests: [MediaRequest]

    let seasonsCount: Int?
    let episodesCount: Int?
    let runtime: Int?

    let rating: String?
    let releaseDate: Date

    private let posterPath: String?
    private let backPath: String?

    var image: URL? {
        guard let posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w300_and_h450_face\(posterPath)")
    }
    
    var backdrop: URL? {
        guard let backPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w1920_and_h800_multi_faces\(backPath)")
    }

    init(data: [String : Any], type: ItemType) {
        self.id = data["id"] as! Int
        self.type = type

        self.title = data[type == .movie ? "title" : "name"] as? String ?? data[type == .movie ? "originalTitle" : "originalName"] as! String
        self.tagline = data["tagline"] as! String
        self.overview = data["overview"] as! String

        self.seasonsCount = data["numberOfSeasons"] as? Int
        self.episodesCount = data["numberOfEpisodes"] as? Int
        self.runtime = data["runtime"] as? Int

        let releaseStr: String = data[type == .movie ? "releaseDate" : "firstAirDate"] as! String
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        self.releaseDate = dateFormatter.date(from: releaseStr) ?? .init(timeIntervalSince1970: 0)

        self.posterPath = data["posterPath"] as? String
        self.backPath = data["backdropPath"] as? String

        // CONDITIONS

        if let mediaInfo: [String: Any] = data["mediaInfo"] as? [String: Any] {
            self.requestStatus = MediaStatus(rawValue: mediaInfo["status"] as! Int) ?? .unknown
            self.requests = (mediaInfo["requests"] as! [[String: Any]]).map { .init(data: $0) }
        } else {
            self.requests = []
            self.requestStatus = .unknown
        }

        if let c: [String: Any] = data["contentRatings"] as? [String: Any], let ratings: [[String: Any]] = c["results"] as? [[String: Any]], let localRating = ratings.filter({ ($0["iso_3166_1"] as? String) == Locale.current.region?.identifier }).first {
            self.rating = localRating["rating"] as? String
        } else {
            self.rating = nil
        }
    }
}

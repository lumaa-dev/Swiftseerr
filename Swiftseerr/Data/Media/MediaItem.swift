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

    let posterPath: String?
    private let backPath: String?

    var inWatchList: Bool

    var image: URL? {
        guard let posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w300_and_h450_face\(posterPath)")
    }
    
    var backdrop: URL? {
        guard let backPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w1920_and_h800_multi_faces\(backPath)")
    }

    var webUrl: URL? {
        return URL(string: "\(SeerSession.shared.auth.address)/\(self.type == .movie ? "movie" : "tv")/\(self.id)")
    }

    init(data: [String : Any], type: ItemType) {
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

        self.inWatchList = data["onUserWatchlist"] as? Bool ?? false

        // CONDITIONS

        if let mediaInfo: [String: Any] = data["mediaInfo"] as? [String: Any] ?? data["media"] as? [String: Any] {
            self.id = mediaInfo["tmdbId"] as? Int ?? data["id"] as! Int
            self.requests = (mediaInfo["requests"] as! [[String: Any]]).map { .init(data: $0) }
            self.requestStatus = Self.allStatus(hd: mediaInfo["status"] as! Int, fourK: mediaInfo["status4k"] as! Int)
        } else {
            self.id = data["tmdbId"] as? Int ?? data["id"] as! Int
            self.requests = []
            self.requestStatus = .unknown
        }

        if let c: [String: Any] = data["contentRatings"] as? [String: Any], let ratings: [[String: Any]] = c["results"] as? [[String: Any]], let localRating = ratings.filter({ ($0["iso_3166_1"] as? String) == Locale.current.region?.identifier }).first {
            self.rating = localRating["rating"] as? String
        } else {
            self.rating = nil
        }
    }

    private static func allStatus(hd: Int, fourK: Int) -> MediaStatus {
        let statusHd: MediaStatus = MediaStatus(rawValue: hd) ?? .unknown
        let status4k: MediaStatus = MediaStatus(rawValue: fourK) ?? .unknown

        return status4k.rawValue > 1 ? status4k : statusHd
    }

    func toDiscover() -> DiscoverItem {
        return .init(id: self.id, name: self.title, imagePath: self.posterPath, type: self.type, inWatchList: self.inWatchList)
    }
}

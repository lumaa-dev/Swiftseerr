// Made by Lumaa

import Foundation

struct MediaItem: Identifiable {
    let id: Int
    let type: ItemType

    let title: String
    let tagline: String
    let overview: String

    var requestHd: MediaStatus
    var request4k: MediaStatus
    var requests: [MediaRequest]

    var jellyfin: URL?

    let seasonsCount: Int?
    let episodesCount: Int?
    let runtime: Int?

    let rating: String?
    let releaseDate: Date

    let posterPath: String?
    private let backPath: String?

    var inWatchList: Bool

    var requestStatus: MediaStatus {
        return self.request4k.rawValue > 1 ? self.request4k : self.requestHd
    }

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
            self.jellyfin = URL(string: mediaInfo["mediaUrl"] as? String ?? "")
            self.requestHd = MediaStatus(rawValue: mediaInfo["status"] as! Int) ?? .unknown
            self.request4k = MediaStatus(rawValue: mediaInfo["status4k"] as! Int) ?? .unknown
            self.requests = (mediaInfo["requests"] as! [[String: Any]]).map { .init(data: $0) }
        } else {
            self.id = data["tmdbId"] as? Int ?? data["id"] as! Int
            self.jellyfin = nil
            self.requestHd = .unknown
            self.request4k = .unknown
            self.requests = []
        }

        if let c = data["contentRatings"] as? [String: Any],
           let ratings = c["results"] as? [[String: Any]],
           let localRating = ratings.first(where: { ($0["iso_3166_1"] as? String) == Locale.current.region?.identifier }) {
            self.rating = localRating["rating"] as? String
        } else if let rels = data["releases"] as? [String: Any],
                  let res = rels["results"] as? [[String: Any]],
                  let cntry = res.first(where: { ($0["iso_3166_1"] as? String) == Locale.current.region?.identifier }),
                  let dates = cntry["release_dates"] as? [[String: Any]],
                  let cert = dates.compactMap({ $0["certification"] as? String }).first {
            self.rating = cert
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

    // Memberwise initializer initializing all stored properties
    init(
        id: Int,
        type: ItemType,
        title: String,
        tagline: String,
        overview: String,
        requestHd: MediaStatus,
        request4k: MediaStatus,
        requests: [MediaRequest],
        jellyfin: URL?,
        seasonsCount: Int?,
        episodesCount: Int?,
        runtime: Int?,
        rating: String?,
        releaseDate: Date,
        posterPath: String?,
        backPath: String?,
        inWatchList: Bool
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.tagline = tagline
        self.overview = overview
        self.requestHd = requestHd
        self.request4k = request4k
        self.requests = requests
        self.jellyfin = jellyfin
        self.seasonsCount = seasonsCount
        self.episodesCount = episodesCount
        self.runtime = runtime
        self.rating = rating
        self.releaseDate = releaseDate
        self.posterPath = posterPath
        self.backPath = backPath
        self.inWatchList = inWatchList
    }

    // Stock example for UI redaction/placeholders
    static var redacted: MediaItem = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return MediaItem(
            id: 244786,
            type: .movie,
            title: "Whiplash",
            tagline: "The road to greatness can take you to the edge.",
            overview: "A promising young drummer enrolls at a cut-throat music conservatory where an abusive instructor pushes him to the brink of his ability and his sanity.",
            requestHd: .unknown,
            request4k: .unknown,
            requests: [],
            jellyfin: nil,
            seasonsCount: nil,
            episodesCount: nil,
            runtime: 107,
            rating: "R",
            releaseDate: formatter.date(from: "2014-10-10") ?? Date(timeIntervalSince1970: 0),
            posterPath: nil,
            backPath: nil,
            inWatchList: false
        )
    }()
}

// Made by Lumaa

import Foundation

struct ShowSeason: Identifiable {
    let id: Int
    let mediaId: Int?

    let name: String
    let summary: String

    let seasonNumber: Int
    let episodes: [ShowEpisode]

    let airDate: Date?

    private let imagePath: String?

    var posterPath: URL? {
        guard let imagePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/original\(imagePath)")
    }

    var episodeCount: Int {
        return episodes.count
    }

    init(data: [String: Any]) {
        self.id = data["id"] as! Int
        self.mediaId = data["showId"] as? Int
        self.name = data["name"] as! String
        self.summary = data["overview"] as! String
        self.seasonNumber = data["seasonNumber"] as! Int
        self.episodes = (data["episodes"] as! [[String: Any]]).map { .init(data: $0) }
        self.airDate = (data["airDate"] as? String)?.seerrDate
        self.imagePath = data["stillPath"] as? String
    }

    init(
        id: Int,
        mediaId: Int,
        name: String,
        summary: String,
        seasonNumber: Int,
        episodes: [ShowEpisode] = [],
        airDate: Date?,
        imagePath: String? = nil
    ) {
        self.id = id
        self.mediaId = mediaId
        self.name = name
        self.summary = summary
        self.seasonNumber = seasonNumber
        self.episodes = episodes
        self.airDate = airDate
        self.imagePath = imagePath
    }

    struct About: Identifiable {
        let id: Int

        let name: String
        let seasonNumber: Int
        let episodeNumber: Int

        let airDate: Date?

        init(data: [String: Any]) {
            self.id = data["id"] as! Int
            self.name = data["name"] as! String
            self.seasonNumber = data["seasonNumber"] as! Int
            self.episodeNumber = data["episodeCount"] as! Int
            self.airDate = (data["airDate"] as? String)?.seerrDate
        }

        init(id: Int, name: String, seasonNumber: Int, episodeNumber: Int, airDate: Date) {
            self.id = id
            self.name = name
            self.seasonNumber = seasonNumber
            self.episodeNumber = episodeNumber
            self.airDate = airDate
        }

        init(from season: ShowSeason) {
            self.id = season.id
            self.name = season.name
            self.seasonNumber = season.seasonNumber
            self.episodeNumber = season.episodeCount
            self.airDate = season.airDate
        }
    }
}

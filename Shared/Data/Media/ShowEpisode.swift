// Made by Lumaa

import Foundation

struct ShowEpisode: Identifiable {
    let id: Int
    let mediaId: Int

    let name: String
    let summary: String

    let inSeason: Int
    let asEpisode: Int

    let airDate: Date?

    private let imagePath: String?

    var posterPath: URL? {
        guard let imagePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/original\(imagePath)")
    }

    init(data: [String: Any]) {
        self.id = data["id"] as! Int
        self.mediaId = data["showId"] as! Int
        self.name = data["name"] as! String
        self.summary = data["overview"] as! String
        self.inSeason = data["seasonNumber"] as! Int
        self.asEpisode = data["episodeNumber"] as! Int
        self.airDate = (data["airDate"] as? String)?.seerrDate
        self.imagePath = data["stillPath"] as? String
    }

    init(
        id: Int,
        mediaId: Int,
        name: String,
        summary: String,
        inSeason: Int,
        asEpisode: Int,
        airDate: Date,
        imagePath: String? = nil
    ) {
        self.id = id
        self.mediaId = mediaId
        self.name = name
        self.summary = summary
        self.inSeason = inSeason
        self.asEpisode = asEpisode
        self.airDate = airDate
        self.imagePath = imagePath
    }
}

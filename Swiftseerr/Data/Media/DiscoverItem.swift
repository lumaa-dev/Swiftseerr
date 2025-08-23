// Made by Lumaa

import Foundation

struct DiscoverItem: Decodable, Identifiable, Equatable {
    let id: Int
    let name: String
    let imagePath: String?
    let type: ItemType

    var image: URL? {
        guard let imagePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w300_and_h450_face\(imagePath)")
    }

    var webUrl: URL? {
        return URL(string: "\(SeerSession.shared.auth.address)/\(self.type == .movie ? "movie" : "tv")/\(self.id)")
    }

    init(id: Int, name: String, imagePath: String, type: ItemType) {
        self.id = id
        self.name = name
        self.imagePath = imagePath
        self.type = type
    }

    init(data: [String: Any]) {
        let strType: String = data["mediaType"] as! String
        self.type = strType == "movie" ? .movie : .show

        self.id = data["tmdbId"] as? Int ?? data["id"] as! Int
        self.name = data[self.type == .movie ? "title" : "name"] as? String ?? data[self.type == .movie ? "originalTitle" : "originalName"] as! String
        self.imagePath = data["posterPath"] as? String
    }

    func fetchMedia() async -> MediaItem? {
        guard let (data, res, _) = try? await SeerSession.shared.raw(Media.get(id: self.id, type: self.type)) else { return nil }
        let code = res?.statusCode ?? -1

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], code == 200 {
            return .init(data: json, type: self.type)
        }
        return nil
    }

    func fetch() async -> DiscoverItem? {
        guard let media: MediaItem = await self.fetchMedia() else { return nil }
        return .init(id: media.id, name: media.title, imagePath: media.posterPath ?? "", type: media.type)
    }
}

// Made by Lumaa

import Foundation

struct DiscoverItem: Decodable, Identifiable {
    let id: Int
    let name: String
    private let imagePath: String?
    let type: Self.ItemType

    var image: URL? {
        guard let imagePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w300_and_h450_face\(imagePath)")
    }

    init(id: Int, name: String, imagePath: String, type: Self.ItemType) {
        self.id = id
        self.name = name
        self.imagePath = imagePath
        self.type = type
    }

    init(data: [String: Any]) {
        let strType: String = data["mediaType"] as! String
        self.type = strType == "movie" ? .movie : .show

        self.id = data["id"] as! Int
        self.name = data[self.type == .movie ? "title" : "name"] as? String ?? data[self.type == .movie ? "originalTitle" : "originalName"] as! String
        self.imagePath = data["posterPath"] as? String
    }

    enum ItemType: String, Decodable {
        case movie
        case show = "tv"
    }
}

// Made by Lumaa

import Foundation

struct MediaItem: Identifiable {
    let id: Int
    let type: ItemType

    let title: String
    let tagline: String
    let overview: String

    var requestStatus: MediaStatus

    private let runtime: Int?

    private let posterPath: String?
    private let backPath: String?

    var movieRuntime: (hours: Double, minutes: Double)? {
        guard let runtime, runtime > 0 else { return nil }
        return (hours: Double(runtime / 60), minutes: Double(runtime - runtime / 60))
    }

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

        self.runtime = data["runtime"] as? Int

        self.posterPath = data["posterPath"] as? String
        self.backPath = data["backdropPath"] as? String

        self.requestStatus = .requestable
        if let mediaInfo: [String: Any] = data["mediaInfo"] as? [String: Any] {
            self.requestStatus = MediaStatus(rawValue: mediaInfo["status"] as! Int) ?? .requestable
        }
    }
}

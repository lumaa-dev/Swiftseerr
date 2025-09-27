// Made by Lumaa

import Foundation

struct DiscoverItem: Identifiable, Equatable {
    let id: Int
    let name: String
    let imagePath: String?
    let type: ItemType

    var requestStatus: MediaStatus
    var inWatchList: Bool

    var image: URL? {
        guard let imagePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w300_and_h450_face\(imagePath)")
    }

    var webUrl: URL? {
        return URL(string: "\(SeerSession.shared.auth.address)/\(self.type == .movie ? "movie" : "tv")/\(self.id)")
    }

    init(
        id: Int,
        name: String,
        imagePath: String?,
        type: ItemType,
        requestStatus: MediaStatus = .unknown,
        inWatchList: Bool = false
    ) {
        self.id = id
        self.name = name
        self.imagePath = imagePath
        self.type = type
        self.requestStatus = requestStatus
        self.inWatchList = inWatchList
    }

    init(data: [String: Any]) {
        let strType: String = data["mediaType"] as! String
        self.type = strType == "movie" ? .movie : .show

        self.id = data["tmdbId"] as? Int ?? data["id"] as! Int
        self.name = data[self.type == .movie ? "title" : "name"] as? String ?? data[self.type == .movie ? "originalTitle" : "originalName"] as? String ?? String(localized: "media.no-name")
        self.imagePath = data["posterPath"] as? String

        if let mediaInfo = data["mediaInfo"] as? [String: Any] {
            self.requestStatus = Self.allStatus(hd: mediaInfo["status"] as! Int, fourK: mediaInfo["status4k"] as! Int)
            self.inWatchList = !(mediaInfo["watchlists"] as? [Any] ?? []).isEmpty
        } else {
            print("[DiscoverItem] NO MEDIA INFO FOR \(self.name)")
            self.requestStatus = .unknown
            self.inWatchList = false
        }
    }

    private static func allStatus(hd: Int, fourK: Int) -> MediaStatus {
        let statusHd: MediaStatus = MediaStatus(rawValue: hd) ?? .unknown
        let status4k: MediaStatus = MediaStatus(rawValue: fourK) ?? .unknown

        return status4k.rawValue > 1 ? status4k : statusHd
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

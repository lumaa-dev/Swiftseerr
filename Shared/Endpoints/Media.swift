// Made by Lumaa

import SwiftUI

enum Media: Endpoint {
    case get(id: Int, type: ItemType)
    case ratings(id: Int, type: ItemType)
    case season(item: MediaItem, season: ShowSeason.About)

    var method: HTTPMethod { .get }

    func path() -> String {
        switch self {
            case .get(let id, let type):
                "\(api)/\(type == .movie ? "movie" : "tv")/\(id)"
            case .ratings(let id, let type):
                "\(api)/\(type == .movie ? "movie" : "tv")/\(id)/ratings"
            case .season(let item, let season):
                "\(api)/tv/\(item.id)/season/\(season.seasonNumber)"
        }
    }
}

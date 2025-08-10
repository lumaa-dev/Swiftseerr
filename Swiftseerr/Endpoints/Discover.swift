// Made by Lumaa

import Foundation

enum Discover: Endpoint {
    case movie
    case show
    case trending

    var method: HTTPMethod { .get }

    func path() -> String {
        switch self {
            case .movie:
                "\(api)/discover/movies"
            case .show:
                "\(api)/discover/tv"
            case .trending:
                "\(api)/discover/trending"
        }
    }

    func queryItems() -> [URLQueryItem]? {
        return []
    }

    static func upcoming(type: DiscoverItem.ItemType) -> URLQueryItem {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let date: String = dateFormatter.string(from: Date.now)
        return .init(name: type == .movie ? "primaryReleaseDateGte" : "firstAirDateGte", value: date)
    }
}

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

    static func upcoming() -> URLQueryItem {
        let date = ISO8601DateFormatter().string(from: Date.now)
        return .init(name: "primaryReleaseDateGte", value: date)
    }
}

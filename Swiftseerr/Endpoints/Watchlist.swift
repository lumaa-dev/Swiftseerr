// Made by Lumaa

import Foundation

enum Watchlist: Endpoint {
    case add(tmdbId: Int, type: ItemType, name: String)
    case remove(tmdbId: Int)
    case get(userId: Int)

    func path() -> String {
        switch self {
            case .add:
                "\(api)/watchlist"
            case .remove(let tmdbId):
                "\(api)/watchlist/\(tmdbId)"
            case .get(let userId):
                "\(api)/user/\(userId)/watchlist"
        }
    }

    var method: HTTPMethod {
        switch self {
            case .add:
                    .post
            case .remove:
                    .delete
            case .get:
                    .get
        }
    }

    func queryItems() -> [URLQueryItem]? {
        switch self {
            case .get(let userId):
                [.init(name: "userId", value: "\(userId)")]
            default:
                nil
        }
    }

    var jsonValue: (any Encodable)? {
        switch self {
            case .add(let id, let type, let name):
                Self.AddData(tmdbId: id, mediaType: type.rawValue, title: name)
            default:
                nil
        }
    }

    private struct AddData: Encodable {
        let tmdbId: Int
        let mediaType: String
        let title: String
    }
}

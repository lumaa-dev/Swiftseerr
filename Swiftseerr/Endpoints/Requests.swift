// Made by Lumaa

import Foundation

enum Requests: Endpoint {
    case all(_ page: Int = 1, limit: Int = 10)
    case create(id: Int, type: ItemType, is4k: Bool)
    case media(id: Int)
    case updateStatus(id: Int, status: Self.Status)
    case delete(id: Int)

    var method: HTTPMethod {
        switch self {
            case .all, .media:
                return .get
            case .create, .updateStatus:
                return .post
            case .delete:
                return .delete
        }
    }

    func path() -> String {
        switch self {
            case .all, .create:
                "\(api)/request"
            case .media(let id), .delete(let id):
                "\(api)/request/\(id)"
            case .updateStatus(let id, let status):
                "\(api)/request/\(id)/\(status.rawValue)"
        }
    }

    func queryItems() -> [URLQueryItem]? {
        switch self {
            case .all(let page, let limit):
                return [.init(name: "skip", value: "\((page - 1) * limit)"), .init(name: "take", value: "\(limit)")]
            default:
                return []
        }
    }

    var jsonValue: (any Encodable)? {
        switch self {
            case .create(let id, let type, let is4k):
                return CreateRequest(mediaId: id, mediaType: type, is4k: is4k)
            default:
                return nil
        }
    }

    struct CreateRequest: Encodable {
        let mediaId: Int
        let mediaType: String
        let is4k: Bool

        init(mediaId: Int, mediaType: ItemType, is4k: Bool) {
            self.mediaId = mediaId
            self.mediaType = mediaType.rawValue
            self.is4k = is4k
        }
    }

    enum Status: String {
        case approve = "approve"
        case decline = "decline"
    }
}

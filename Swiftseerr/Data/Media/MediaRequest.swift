// Made by Lumaa

import Foundation

struct MediaRequest: Identifiable {
    let id: Int
    let mediaId: Int?

    let status: MediaStatus
    let requestedBy: User
    let type: ItemType

    init(id: Int, mediaId: Int?, status: MediaStatus, requestedBy: User, type: ItemType) {
        self.id = id
        self.mediaId = mediaId
        self.status = status
        self.requestedBy = requestedBy
        self.type = type
    }

    init(data: [String: Any]) {
        self.id = data["id"] as! Int
        self.status = .init(rawValue: data["status"] as! Int) ?? .unknown
        self.type = .init(rawValue: data["type"] as! String) ?? .movie
        self.requestedBy = .init(data: data["requestedBy"] as! [String: Any])

        if let media = data["media"] as? [String: Any] {
            self.mediaId = media["id"] as? Int
        } else {
            self.mediaId = nil
        }
    }
}

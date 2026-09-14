// Made by Lumaa

import Foundation

struct MediaRequest: Identifiable, Equatable {
    let id: Int
    let mediaId: Int?

    var status: MediaStatus
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
            self.mediaId = media["tmdbId"] as? Int
        } else {
            self.mediaId = nil
        }
    }

    /// Non-trapping counterpart to `init(data:)`.
    ///
    /// The force-unwraps above take down the whole process on an unexpected payload, which in a widget
    /// extension means the widget simply never renders. Returns `nil` instead so a malformed entry can
    /// be skipped.
    init?(safely data: [String: Any]) {
        guard let id = data["id"] as? Int,
              let requestedBy = data["requestedBy"] as? [String: Any] else {
            return nil
        }

        self.id = id
        self.status = MediaStatus(rawValue: data["status"] as? Int ?? -1) ?? .unknown
        self.type = ItemType(rawValue: data["type"] as? String ?? "") ?? .movie
        self.requestedBy = .init(data: requestedBy)
        self.mediaId = (data["media"] as? [String: Any])?["tmdbId"] as? Int
    }

    func getMedia() async throws -> MediaItem {
        guard let mediaId else { throw SeerrError() }

        let (data, http, _) = try await SeerSession.shared.raw(Media.get(id: mediaId, type: self.type))
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], http?.statusCode == 200 {
            return .init(data: json, type: self.type)
        } else {
            throw SeerrError()
        }
    }

	static var redacted: MediaRequest { self.init(id: 1, mediaId: 244786, status: .unknown, requestedBy: .redacted, type: .unknown) }
}

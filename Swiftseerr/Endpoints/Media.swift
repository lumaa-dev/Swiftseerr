// Made by Lumaa

import SwiftUI

enum Media: Endpoint {
    case get(id: Int, type: ItemType)
    case ratings(id: Int, type: ItemType)
    case season(id: Int, seasonId: Int)

    var method: HTTPMethod { .get }

    func path() -> String {
        switch self {
            case .get(let id, let type):
                "\(api)/\(type == .movie ? "movie" : "tv")/\(id)"
            case .ratings(let id, let type):
                "\(api)/\(type == .movie ? "movie" : "tv")/\(id)/ratings"
            case .season(let id, let seasonId):
                "\(api)/tv/\(id)/season/\(seasonId)"
        }
    }
}

enum MediaStatus: Int {
    case unknown = 1
    case pending = 2
    case processing = 3
    case partiallyAvailable = 4
    case available = 5
    case blacklisted = 6
    case deleted = 7

    var localized: String {
        switch self {
            case .unknown:
                String(localized: "request.status.unknown")
            case .pending:
                String(localized: "request.status.pending")
            case .processing:
                String(localized: "request.status.processing")
            case .partiallyAvailable:
                String(localized: "request.status.partially-available")
            case .available:
                String(localized: "request.status.available")
            case .blacklisted:
                String(localized: "request.status.blacklisted")
            case .deleted:
                String(localized: "request.status.deleted")
        }
    }

    var color: Color {
        switch self {
            case .unknown:
                Color.clear
            case .pending:
                Color.orange
            case .processing:
                Color.orange
            case .partiallyAvailable:
                Color.yellow
            case .available:
                Color.green
            case .blacklisted:
                Color.black
            case .deleted:
                Color.red
        }
    }
}

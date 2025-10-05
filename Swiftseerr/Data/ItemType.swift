// Made by Lumaa

import Foundation

enum ItemType: String, Decodable {
    case movie
    case show = "tv"

    var localized: LocalizedStringResource {
        switch self {
            case .movie:
                LocalizedStringResource("movie")
            case .show:
                LocalizedStringResource("show")
        }
    }
}

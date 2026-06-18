// Made by Lumaa

import Foundation

enum ItemType: String, Codable {
    case movie
    case show = "tv"
	case unknown

    var localized: LocalizedStringResource {
        switch self {
            case .movie:
                LocalizedStringResource("movie")
            case .show:
                LocalizedStringResource("show")
			case .unknown:
				LocalizedStringResource("unknown")
        }
    }
}

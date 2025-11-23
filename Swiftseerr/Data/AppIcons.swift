// Made by Lumaa

import SwiftUI

enum AppIcons: String, Equatable, Hashable, CaseIterable {
    case jelly = "Jellyseerr"
    case over = "Overseerr"
    case overjelly = "OverJelly"

    static func set(_ icon: Self) {
        UIApplication.shared.setAlternateIconName(icon.rawValue)
    }

    var representation: Image {
        switch self {
            case .jelly:
                Image(.jellyseerr)
            case .over:
                Image(.overseerr)
            case .overjelly:
                Image(.overJelly)
        }
    }
}

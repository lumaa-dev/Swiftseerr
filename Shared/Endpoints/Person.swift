// Made by Lumaa

import Foundation

enum Person: Endpoint {
    case get(id: Int)
    case content(id: Int)

    func path() -> String {
        switch self {
            case .get(let id):
                return "\(api)/person/\(id)"
            case .content(let id):
                return "\(api)/person/\(id)/combined_credits"
        }
    }

    var method: HTTPMethod { .get }
}

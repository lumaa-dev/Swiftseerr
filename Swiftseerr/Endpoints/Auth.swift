// Made by Lumaa

import Foundation

enum Identify: Endpoint {
    case status(url: String)

    var method: HTTPMethod { return .get }

    func path() -> String {
        switch self {
            case .status(let url):
                return "\(url)/api/v1/status"
        }
    }

    func queryItems() -> [URLQueryItem]? {
        return nil
    }
}

enum Login: Endpoint {
    case jellyfin(username: String, password: String)
    case local(email: String, password: String)
    case logout

    func path() -> String {
        switch self {
            case .jellyfin:
                return "\(api)/auth/jellyfin"
            case .local:
                return "\(api)/auth/local"
            case .logout:
                return "\(api)/auth/logout"
        }
    }

    var method: HTTPMethod { .post }

    var jsonValue: (any Encodable)? {
        switch self {
            case .jellyfin(let username, let password):
                return JellyfinLogin(username: username, password: password)
            case .local(let email, let password):
                return LocalLogin(email: email, password: password)
            default:
                return nil
        }
    }

    func queryItems() -> [URLQueryItem]? {
        return nil
    }

    struct JellyfinLogin: Encodable {
        let username: String
        let password: String
    }

    struct LocalLogin: Encodable {
        let email: String
        let password: String
    }
}

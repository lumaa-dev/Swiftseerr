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

    func path() -> String {
        let api: String = "\(self.source)/api/v1"

        switch self {
            case .jellyfin:
                return "\(api)/auth/jellyfin"
        }
    }

    var method: HTTPMethod {
        switch self {
            case .jellyfin:
                return .post
        }
    }

    var jsonValue: (any Encodable)? {
        switch self {
            case .jellyfin(let username, let password):
                return JellyfinLogin(username: username, password: password)
        }
    }

    func queryItems() -> [URLQueryItem]? {
        return nil
    }
}

struct JellyfinLogin: Encodable {
    let username: String
    let password: String
}

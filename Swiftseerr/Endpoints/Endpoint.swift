// Made by Lumaa

import Foundation

protocol Endpoint: Sendable {
    func path() -> String
    func queryItems() -> [URLQueryItem]?
    var jsonValue: Encodable? { get }
    var method: HTTPMethod { get }
}

extension Endpoint {
    var jsonValue: Encodable? {
        nil
    }

    var source: String { SeerSession.shared.auth.address }
    var api: String { "\(SeerSession.shared.auth.address)/api/v1" }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

struct SeerrError: Error {}

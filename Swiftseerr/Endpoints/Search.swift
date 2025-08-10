// Made by Lumaa

import Foundation

enum Search: Endpoint {
    case global(_ query: String)
    case keywords(_ query: String)
    case companies(_ query: String)

    var method: HTTPMethod { .get }

    func path() -> String {
        switch self {
            case .global:
                "\(api)/search"
            case .keywords:
                "\(api)/search/keyword"
            case .companies:
                "\(api)/search/company"
        }
    }

    func queryItems() -> [URLQueryItem]? {
        switch self {
            case .global(let q):
                return [.init(name: "query", value: q)]
            case .keywords(let q):
                return [.init(name: "query", value: q)]
            case .companies(let q):
                return [.init(name: "query", value: q)]
        }
    }
}

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
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

class CookieCatchingDelegate: NSObject, URLSessionTaskDelegate {
    var lastCookies: [HTTPCookie] = []

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = response.url {
            let headers = response.allHeaderFields.reduce(into: [String:String]()) {
                if let k = $1.key as? String, let v = $1.value as? String {
                    $0[k] = v
                }
            }
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: headers, for: url)
            lastCookies.append(contentsOf: cookies)
        }
        completionHandler(request) // follow the redirect
    }
}

struct SeerrError: Error {}

// Made by Lumaa

import Foundation

class SeerSession {
    static let shared: SeerSession = .init()

    var auth: AuthInfo
    var authorization: String? = nil

    init(auth: AuthInfo = .init()) {
        self.auth = auth
    }

    func call<Response: Decodable>(_ endpoint: Endpoint, queries: [URLQueryItem] = []) async throws -> Response {
        let data = try await self.raw(endpoint).0
        let result = try JSONDecoder().decode(Response.self, from: data)
        return result
    }

    func raw(_ endpoint: Endpoint, queries: [URLQueryItem] = []) async throws -> (Data, HTTPURLResponse?, [(name: String, value: String)]) {
        var strUrl: String = endpoint.path()
        if !queries.isEmpty {
            let q: [URLQueryItem] = queries.encodeQueryItemValues()
            strUrl = "\(endpoint.path())?\(q.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&"))"
        }
        
        guard let url = URL(string: strUrl) else {
            throw URLError(.badURL)
        }

        print("[SeerSession] \(endpoint.method.rawValue) \(strUrl)")

        var req = URLRequest(url: url)
        req.httpMethod = endpoint.method.rawValue

        if let json = endpoint.jsonValue {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            req.httpBody = try encoder.encode(json)
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        if let authorization {
            print("[SeerSession] Cookie header set")
            req.setValue("connect.sid=\(authorization)", forHTTPHeaderField: "Cookie")
        }

        let cookieStorage: HTTPCookieStorage = .init()
        cookieStorage.cookieAcceptPolicy = .always

        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.httpCookieStorage = cookieStorage

        let session = URLSession(configuration: config)

        let (data, res) = try await session.data(for: req)

        var cookies: [(name: String, value: String)] = []
        if let http = res as? HTTPURLResponse {
//            print("🔍 Response Headers:")
//            for (key, value) in http.allHeaderFields {
//                print("  \(key): \(value)")
//            }

            let rawResponse: String? = String(data: data, encoding: .utf8)
            print("[\(http.statusCode)] \(rawResponse ?? "*No content*")")

            let stringCookies = http.value(forHTTPHeaderField: "Set-Cookie") ?? ""
            let arrayCookies = stringCookies.split(separator: /(; ?)+/)
            cookies = arrayCookies.map {
                let s = $0.split(separator: "=")
                return (name: "\(s[0])", value: "\(s.count > 1 ? s[1] : "")")
            }
        }

        return (data, res as? HTTPURLResponse, cookies)
    }

    func saveAuth() throws {
        let data: Data = try JSONEncoder().encode(self.auth)
        UserDefaults.standard.set(data, forKey: "auth")
        print("[SeerSession] - Saved auth")
    }

    func loadAuth() throws -> AuthInfo {
        guard let data: Data = UserDefaults.standard.data(forKey: "auth") else { throw SeerrError() }
        self.auth = try JSONDecoder().decode(AuthInfo.self, from: data)
        print("[SeerSession] - Loaded auth")
        return self.auth
    }

    enum OnboardingSteps: Int, CaseIterable {
        case welcome = 1
        case url = 2
        case provider = 3
        case login = 4
        case complete = 5

        var title: String {
            switch self {
                case .welcome:
                    "Swiftseerr"
                case .url:
                    String(localized: "onboarding.url.title")
                case .provider:
                    String(localized: "onboarding.provider.title")
                case .login:
                    String(localized: "onboarding.login.title")
                default:
                    ""
            }
        }

        var description: String {
            switch self {
                case .welcome:
                    String(localized: "onboarding.welcome")
                case .url:
                    String(localized: "onboarding.url")
                case .provider:
                    String(localized: "onboarding.provider")
                case .login:
                    String(localized: "onboarding.login")
                default:
                    ""
            }
        }
    }
}

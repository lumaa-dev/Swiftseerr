// Made by Lumaa

import Foundation
import SwiftUI
import SwiftData

class SeerSession {
    static var shared: SeerSession = .init()

    var auth: AuthInfo
    var user: User? = nil
    var authorization: String? = nil

    init(auth: AuthInfo = .init()) {
        self.auth = auth
    }

    func call<Response: Decodable>(_ endpoint: Endpoint, queries: [URLQueryItem] = []) async throws -> Response {
        let data = try await self.raw(endpoint).0
        let result = try JSONDecoder().decode(Response.self, from: data)
        return result
    }

    func raw(_ endpoint: Endpoint, queries: [URLQueryItem] = [], useCookies: Bool = true) async throws -> (Data, HTTPURLResponse?, [(name: String, value: String)]) {
        var strUrl: String = endpoint.path()
        var q: [URLQueryItem] = endpoint.queryItems() ?? []
        q.append(contentsOf: queries)
        
        if !q.isEmpty {
            q = q.encodeQueryItemValues()

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

            print("Sending JSON: \(json)")
        }
        
        if let authorization, useCookies {
            print("[SeerSession] Cookie header set")
            req.setValue("connect.sid=\(authorization)", forHTTPHeaderField: "Cookie")
        }

        let cookieStorage: HTTPCookieStorage = .init()
        cookieStorage.cookieAcceptPolicy = useCookies ? .always : .never

        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = useCookies ? .always : .never
        config.httpShouldSetCookies = useCookies
        config.httpCookieStorage = cookieStorage

        let session = URLSession(configuration: config)

        let (data, res) = try await session.data(for: req)

        var cookies: [(name: String, value: String)] = []
        if let http = res as? HTTPURLResponse {
            let rawResponse: String? = String(data: data, encoding: .utf8)
            print("[\(http.statusCode)] \(rawResponse ?? "*No content*")")

            let stringCookies = http.value(forHTTPHeaderField: "Set-Cookie") ?? ""
            let arrayCookies = stringCookies.split(separator: /(; ?)+/)
            cookies = arrayCookies.map {
                let s = $0.split(separator: "=")
                return (name: "\(s[0])", value: "\(s.count > 1 ? s[1] : "")")
            }

            print("Cookies received:")
            print(cookies.map { "\($0.name): \($0.value)" })
        }

        return (data, res as? HTTPURLResponse, cookies)
    }

    func clear() {
        self.auth = .init()
        self.authorization = nil
        self.user = nil
    }

    enum OnboardingSteps: CaseIterable, Equatable {
        case welcome
        case url
        case provider
        case login(_ provider: AuthInfo.Providers? = nil)
        case complete

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

        @ViewBuilder
        var badge: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 14.0)
                    .fill(self.color)
                    .frame(width: 50.0, height: 50.0)

                Image(systemName: self.symbol)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30.0, height: 30.0)
                    .foregroundStyle(Color.primary)
            }
        }

        private var color: Color {
            switch self {
                case .welcome:
                    Color.accentPurple
                case .url, .provider:
                    Color.gray
                case .login:
                    Color.orange
                case .complete:
                    Color.green
            }
        }

        private var symbol: String {
            switch self {
                case .welcome:
                    "hand.wave.fill"
                case .url:
                    "server.rack"
                case .provider:
                    "externaldrive.badge.person.crop"
                case .login:
                    "person.crop.square.filled.and.at.rectangle.fill"
                case .complete:
                    "checkmark"
            }
        }

        static var allCases: [SeerSession.OnboardingSteps] {
            [
                .welcome,
                .url,
                .provider,
                .login(nil), // nil until selected .provider
                .complete
            ]
        }

        static func isLogin(_ step: Self) -> Bool {
            return step == .login(nil) || step == .login(.jellyfin) || step == .login(.local)
        }
    }
}

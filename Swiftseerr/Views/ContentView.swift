// Made by Lumaa

import SwiftUI

struct ContentView: View {
    @State private var onboarding: SeerSession.OnboardingSteps = .complete

    @State private var loading: Bool = false
    @State private var searchQuery: String = ""

    var body: some View {
        ZStack {
            if loading {
                ProgressView()
                    .progressViewStyle(.circular)
            } else {
                if self.onboarding != SeerSession.OnboardingSteps.complete {
                    OnboardingView(onboarding: $onboarding)
                } else if SeerSession.shared.authorization != nil {
                    tabs
                }
            }
        }
        .task {
            defer { self.loading = false }
            self.loading = true

            do {
                let loaded: AuthInfo = try SeerSession.shared.loadAuth()
                try await logIn(auth: loaded)

                let isLogged: Bool = SeerSession.shared.authorization?.isEmpty == false

                self.onboarding = UserDefaults.standard.bool(forKey: "onboarded") && isLogged ? .complete : .welcome
            } catch {
                self.onboarding = .welcome
                print(error)
            }
        }
    }

    //MARK: - Views

    @ViewBuilder
    private var tabs: some View {
        TabView {
            Tab {
                DiscoverView()
            } label: {
                Label("discover", systemImage: "sparkles")
            }

            Tab {
                DiscoverItemsView(type: .movie)
            } label: {
                Label("movies", systemImage: "film.stack")
            }

            Tab {
                DiscoverItemsView(type: .show)
            } label: {
                Label("shows", systemImage: "play.tv")
            }

            Tab(role: .search) {
                SearchView(query: $searchQuery)
            }
        }
        .searchable(text: $searchQuery, prompt: "search.prompt")
        .tabBarMinimizeBehavior(.onScrollDown)
    }

    //MARK: - Methods

    private func logIn(auth: AuthInfo) async throws {
        guard !auth.address.isEmpty && !auth.password.isEmpty && auth.provider != nil else { throw SeerrError() }

        let endpoint: Login = auth.provider! == .jellyfin ? Login.jellyfin(username: auth.username, password: auth.password) : Login.local(email: auth.username, password: auth.password)
        let (data, res, cookies) = try await SeerSession.shared.raw(endpoint)
        let code = res?.statusCode ?? -1

        if let json = try JSONSerialization.jsonObject(with: data) as? [String : Any], code == 200 {
            if let sid = cookies.first(where: { $0.name == "connect.sid" }) {
                SeerSession.shared.auth = auth
                SeerSession.shared.authorization = sid.value
                SeerSession.shared.user = .init(data: json)

                print("[logIn] Cookie bound \(sid.value)")
                UserDefaults.standard.set(true, forKey: "onboarded")
            }
        } else {
            throw SeerrError()
        }

        try await self.getMe()
    }

    private func getMe() async throws {
        guard let user = SeerSession.shared.user, user.permission <= 0 else { return }

        let (data, res, _) = try await SeerSession.shared.raw(Identify.me)
        let code = res?.statusCode ?? -1

        if let json = try JSONSerialization.jsonObject(with: data) as? [String : Any], code == 200 {
            SeerSession.shared.user = .init(data: json)
            print("[getMe] Updated user")
        } else {
            throw SeerrError()
        }
    }
}


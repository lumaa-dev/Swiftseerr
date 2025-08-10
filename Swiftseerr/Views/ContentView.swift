// Made by Lumaa

import SwiftUI

struct ContentView: View {
    @State private var onboarding: SeerSession.OnboardingSteps = .complete

    @State private var loading: Bool = false

    var body: some View {
        ZStack {
            if self.onboarding != SeerSession.OnboardingSteps.complete {
                OnboardingView(onboarding: $onboarding)
            } else {
                tabs
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
                Text("C'est pas fini. T'attends comme tout le monde.")
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }

    //MARK: - Methods

    private func logIn(auth: AuthInfo) async throws {
        guard !auth.address.isEmpty && !auth.password.isEmpty else { throw SeerrError() }
        
        let (data, res, cookies) = try await SeerSession.shared.raw(Login.jellyfin(username: auth.username, password: auth.password))
        let code = res?.statusCode ?? -1

        if let json = try JSONSerialization.jsonObject(with: data) as? [String : Any], json["id"] != nil && code == 200 {
            if let sid = cookies.first(where: { $0.name == "connect.sid" }) {
                SeerSession.shared.auth = auth
                SeerSession.shared.authorization = sid.value

                print("[logIn] Cookie bounded \(sid.value)")
                UserDefaults.standard.set(true, forKey: "onboarded")
            }
        } else {
            throw SeerrError()
        }
    }
}


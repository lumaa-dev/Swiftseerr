// Made by Lumaa

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.isSearching) private var isSearching: Bool

    @AppStorage("MyTabViewCustomization")
    private var customization: TabViewCustomization

    @Query private var auths: [AuthInfo]

    @State private var onboarding: SeerSession.OnboardingSteps = .complete

    @State private var loading: Bool = false

    var body: some View {
        ZStack {
            if loading {
                Color.bgPurple
                    .ignoresSafeArea()
                
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
                guard let loaded: AuthInfo = self.auths.first else { throw SeerrError() }
                
                SeerSession.shared.auth = loaded
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
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.bigTabs
        } else {
            self.smallTabs
        }
    }

    @ViewBuilder
    private var bigTabs: some View {
        TabView {
            Tab {
                DiscoverView()
            } label: {
                Label("discover", systemImage: "sparkles")
            }
            .customizationID("discover")

            Tab {
                RequestView()
            } label: {
                Label("requests", systemImage: "clock")
            }
            .customizationID("requests")

            Tab {
                DiscoverItemsView("upcoming.shows", endpoint: Discover.trending)
            } label: {
                Label("trending", systemImage: "chart.line.uptrend.xyaxis")
            }
            .customizationID("trending")

            Tab(role: .search) {
                SearchView()
            }
            .customizationBehavior(.disabled, for: .automatic, .sidebar, .tabBar)

            TabSection("all.movies") {
                Tab {
                    DiscoverItemsView("movies", endpoint: Discover.movie)
                } label: {
                    Label("movies", systemImage: "film.stack")
                }
                .customizationID("movies")

                Tab {
                    DiscoverItemsView(
                        "upcoming.movies",
                        endpoint: Discover.movie,
                        additionalQueries: [Discover.upcoming(type: .movie)]
                    )
                } label: {
                    Label("upcoming.movies", systemImage: "calendar.badge.clock")
                }
                .customizationID("upcoming.movies")
            }

            TabSection("all.shows") {
                Tab {
                    DiscoverItemsView("shows", endpoint: Discover.show)
                } label: {
                    Label("shows", systemImage: "play.tv")
                }
                .customizationID("shows")

                Tab {
                    DiscoverItemsView(
                        "upcoming.shows",
                        endpoint: Discover.show,
                        additionalQueries: [Discover.upcoming(type: .show)]
                    )
                } label: {
                    Label("upcoming.shows", systemImage: "globe.badge.clock")
                }
                .customizationID("upcoming.shows")
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabViewCustomization($customization)
        .defaultAdaptableTabBarPlacement(.tabBar)
        .tabBarMinimizeBehavior(.onScrollDown)
        .onAppear {
            customization.resetSectionOrder()
            customization.resetVisibility()
        }
    }

    @ViewBuilder
    private var smallTabs: some View {
        TabView {
            Tab {
                DiscoverView()
            } label: {
                Label("discover", systemImage: "sparkles")
            }

            Tab {
                DiscoverItemsView("movies", endpoint: Discover.movie)
            } label: {
                Label("movies", systemImage: "film.stack")
            }

            Tab {
                DiscoverItemsView("shows", endpoint: Discover.show)
            } label: {
                Label("shows", systemImage: "play.tv")
            }

            Tab {
                RequestView()
            } label: {
                Label("requests", systemImage: "clock")
            }

            Tab(role: .search) {
                SearchView()
            }
        }
        .tabViewStyle(.tabBarOnly)
        .tabBarMinimizeBehavior(.onScrollDown)
        .defaultAdaptableTabBarPlacement(.tabBar)
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


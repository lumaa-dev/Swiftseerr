// Made by Lumaa

import SwiftUI
import SwiftData

struct ContentView: View {
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass: UserInterfaceSizeClass?
	@Environment(\.openURL) private var openURL: OpenURLAction

    @AppStorage("AppTabs") private var customization: TabViewCustomization

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
        .preferredColorScheme(ColorScheme.dark)
        .task {
            defer { self.loading = false }
            self.loading = true

            do {
                guard let loaded: AuthInfo = self.auths.first else { throw SeerrError() }
                
                SeerSession.shared.auth = loaded
                try await logIn(auth: loaded)

                let isLogged: Bool = SeerSession.shared.authorization?.isEmpty == false
				if isLogged {
					_ = await self.sendToken()
				}

                self.onboarding = UserDefaults.standard.bool(forKey: "onboarded") && isLogged ? .complete : .welcome
            } catch {
                self.onboarding = .welcome
                print(error)
            }
        }
		.environment(\.openURL, OpenURLAction { url in
			print("[openURL+handle] Handling \(url.absoluteString)")
			return DeeplinkManager.handle(url)
		})
		.onOpenURL(perform: { url in
			print("[openURL+handle] Handling \(url.absoluteString)")
			_ = DeeplinkManager.handle(url)
		})
    }

    //MARK: - Views

    @ViewBuilder
    private var tabs: some View {
        #if canImport(UIKit)
		if UIDevice.current.userInterfaceIdiom == .pad && self.horizontalSizeClass == .regular {
            self.bigTabs
        } else {
            self.smallTabs
        }
        #else
        self.bigTabs
        #endif
    }

    @ViewBuilder
    private var bigTabs: some View {
		TabView(selection: Binding(get: { Navigator.shared.selectedTab }, set: { Navigator.shared.selectedTab = $0 })) {
			Tab(value: Navigator.Tabs.search) {
				Navigator.Tabs.search.content
			} label: {
				Navigator.Tabs.search.label
			}

			Tab(value: Navigator.Tabs.discover) {
				Navigator.Tabs.discover.content
			} label: {
				Navigator.Tabs.discover.label
			}
			.customizationID("discover")

			Tab(value: Navigator.Tabs.requests) {
				Navigator.Tabs.requests.content
			} label: {
				Navigator.Tabs.requests.label
			}
			.customizationID("requests")

            TabSection("all.movies") {
				Tab(value: Navigator.Tabs.movies) {
					Navigator.Tabs.movies.content
                } label: {
					Navigator.Tabs.movies.label
                }
                .customizationID("movies")

				Tab(value: Navigator.Tabs.upcomingMovies) {
					Navigator.Tabs.upcomingMovies.content
				} label: {
					Navigator.Tabs.upcomingMovies.label
				}
                .customizationID("upcoming.movies")
            }

            TabSection("all.shows") {
				Tab(value: Navigator.Tabs.shows) {
					Navigator.Tabs.shows.content
				} label: {
					Navigator.Tabs.shows.label
				}
                .customizationID("shows")

				Tab(value: Navigator.Tabs.upcomingShows) {
					Navigator.Tabs.upcomingShows.content
				} label: {
					Navigator.Tabs.upcomingShows.label
				}
                .customizationID("upcoming.shows")
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabViewCustomization($customization)
        #if !os(macOS)
        .defaultAdaptableTabBarPlacement(.tabBar)
        .tabBarMinimizeBehavior(.onScrollDown)
        #endif
		#if DEBUG
        .onAppear {
            customization.resetSectionOrder()
            customization.resetVisibility()
        }
		#endif
    }

    @ViewBuilder
    private var smallTabs: some View {
		TabView(selection: Binding(get: { Navigator.shared.selectedTab }, set: { Navigator.shared.selectedTab = $0 })) {
			Tab(value: Navigator.Tabs.discover) {
				Navigator.Tabs.discover.content
			} label: {
				Navigator.Tabs.discover.label
			}

			Tab(value: Navigator.Tabs.movies) {
				Navigator.Tabs.movies.content
			} label: {
				Navigator.Tabs.movies.label
			}

			Tab(value: Navigator.Tabs.shows) {
				Navigator.Tabs.shows.content
			} label: {
				Navigator.Tabs.shows.label
			}

			Tab(value: Navigator.Tabs.requests) {
				Navigator.Tabs.requests.content
			} label: {
				Navigator.Tabs.requests.label
			}

			Tab(value: Navigator.Tabs.search, role: .search) {
				Navigator.Tabs.search.content
			} label: {
				Navigator.Tabs.search.label
			}
        }
        .tabViewStyle(.tabBarOnly)
        #if !os(macOS)
        .tabBarMinimizeBehavior(.onScrollDown)
        .defaultAdaptableTabBarPlacement(.tabBar)
        #endif
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

	private func sendToken() async -> Bool {
		guard let urll: URL = URL(string: "\(UserDefaults.standard.string(forKey: "notifUrl") ?? "")/token"), let auth = UserDefaults.standard.string(forKey: "notifAuth") else {
			return false
		}

		var req: URLRequest = .init(url: urll, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 300)
		req.setValue(auth, forHTTPHeaderField: "Authorization")
		req.httpBody = "deviceToken=\(AppDelegate.deviceToken)&seerrId=\(SeerSession.shared.user?.id ?? -1)&permissions=\(SeerSession.shared.user?.permission ?? -1)"
			.data(using: .utf8)
		req.httpMethod = "POST"

		print("deviceToken=\(AppDelegate.deviceToken)&seerrId=\(SeerSession.shared.user?.id ?? -1)&permissions=\(SeerSession.shared.user?.permission ?? -1)")

		do {
			let res: URLResponse = try await URLSession.shared.data(for: req).1
			if let http = res as? HTTPURLResponse {
				return http.statusCode == 200
			} else {
				return false
			}
		} catch {
			print(error)
		}

		return false
	}
}


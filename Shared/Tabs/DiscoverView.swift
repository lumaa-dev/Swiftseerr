// Made by Lumaa

import SwiftUI

struct DiscoverView: View {
    @State private var watchlist: ([DiscoverItem], Bool) = ([], false)
    @State private var requests: ([MediaRequest], Bool) = ([], false)

    @State private var trending: ([DiscoverItem], Bool) = ([], false)

    @State private var movies: ([DiscoverItem], Bool) = ([], false)
    @State private var shows: ([DiscoverItem], Bool) = ([], false)

    @State private var upMovies: ([DiscoverItem], Bool) = ([], false)
    @State private var upShows: ([DiscoverItem], Bool) = ([], false)

    var body: some View {
        ZStack {
			self.nav
        }
        .task {
			let infolessList: [DiscoverItem] = await self.fetchItems(endpoint: Discover.watchlist).0
            self.watchlist = (infolessList, false)
            self.requests = await self.fetchRequests()

            self.trending = await self.fetchItems(endpoint: Discover.trending)

            self.movies = await self.fetchItems(endpoint: Discover.movie)
            self.shows = await self.fetchItems(endpoint: Discover.show)

            self.upMovies = await self.fetchItems(endpoint: Discover.movie, queries: [Discover.upcoming(type: .movie)])
            self.upShows = await self.fetchItems(endpoint: Discover.show, queries: [Discover.upcoming(type: .show)])

			for item in infolessList {
				guard var fetchedItem = await item.fetch(), let index = self.watchlist.0.firstIndex(of: item) else { continue }
                fetchedItem.inWatchList = true
				self.watchlist.0[index] = fetchedItem
            }

			self.watchlist = (self.watchlist.0, true)
        }
    }

	@ContentBuilder
	private var nav: some View {
		NavigationStack(path: Binding(get: { Navigator.shared.navigationPath[Navigator.Tabs.discover] ?? [] }, set: { Navigator.shared.navigationPath[Navigator.Tabs.discover] = $0 } )) {
			ScrollView {
				LazyVStack(spacing: 32) {
					VScrollItems("my.watchlist") {
						if self.watchlist.1 {
							self.discoverH(self.watchlist.0)
						} else {
							self.redactedH(5)
						}
					}
					.canScroll(self.watchlist.1)

					#if !os(tvOS)
					VScrollItems("recent.requests") {
						if self.requests.1 {
							self.requestsH(self.requests.0)
						} else {
							self.redactedReqH()
						}
					}
					.canScroll(self.requests.1)
					#endif

					NavigationVScrollItems("trending") {
						DiscoverItemsView("trending", endpoint: Discover.trending)
					} content: {
						if self.trending.1 {
							self.discoverH(self.trending.0)
						} else {
							self.redactedH(5)
						}
					}
					.canScroll(self.trending.1)

					VScrollItems("movies") {
						if self.movies.1 {
							self.discoverH(self.movies.0)
						} else {
							self.redactedH(5)
						}
					}
					.canScroll(self.movies.1)

					VScrollItems("shows") {
						if self.shows.1 {
							self.discoverH(self.shows.0)
						} else {
							self.redactedH(5)
						}
					}
					.canScroll(self.shows.1)


					VScrollItems("networks") {
						HStack(spacing: 8) {
							ForEach(Networks.allCases, id: \.network) { network in
								NetworkCard(network)
							}
						}
					}

					VScrollItems("upcoming.movies") {
						if self.upMovies.1 {
							self.discoverH(self.upMovies.0)
						} else {
							self.redactedH(5)
						}
					}
					.canScroll(self.upMovies.1)

					VScrollItems("upcoming.shows") {
						if self.upShows.1 {
							self.discoverH(self.upShows.0)
						} else {
							self.redactedH(5)
						}
					}
					.canScroll(self.upShows.1)


					VScrollItems("studios") {
						HStack(spacing: 8) {
							ForEach(Studios.allCases, id: \.studio) { studio in
								NetworkCard(studio)
							}
						}
					}
				}
				.padding(.bottom)
			}
			.navigator()
			#if !os(tvOS)
			.navigationTitle(Text("discover"))
			.toolbarTitleDisplayMode(.inlineLarge)
			.scrollContentBackground(.hidden)
			#endif
			.background {
				Color.bgPurple.ignoresSafeArea()
			}
			.refreshable {
				self.requests = await self.fetchRequests()
				let infolessList: [DiscoverItem] = await self.fetchItems(endpoint: Discover.watchlist).0
				self.watchlist = (infolessList, false)

				for item in infolessList {
					guard var fetchedItem = await item.fetch(), let index = self.watchlist.0.firstIndex(of: item) else { return }
					fetchedItem.inWatchList = true
					if index <= self.watchlist.0.count - 1 {
						self.watchlist.0[index] = fetchedItem
					} else {
						self.watchlist.0.append(fetchedItem)
					}
				}

				self.watchlist = (self.watchlist.0, true)
			}
			#if !os(tvOS)
			.addSettings()
			#endif
		}
	}

    private func fetchItems(endpoint: Discover, queries: [URLQueryItem] = []) async -> ([DiscoverItem], Bool) {
        guard let (data, _, _) = try? await SeerSession.shared.raw(endpoint, queries: queries), let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ([], true)
        }

        let results: [[String: Any]]? = json["results"] as? [[String: Any]]

        if results?.isEmpty == false {
            let viewBlacklist: Bool = SeerSession.shared.user?.hasPermission(Permission.viewBlacklist) ?? false

            let fetched: [DiscoverItem] = results!.map { .init(data: $0) }.filter { $0.requestStatus != .blacklisted || viewBlacklist }
            return (fetched, true)
        }
        return ([], true)
    }

    private func fetchRequests(_ page: Int = 1) async -> ([MediaRequest], Bool) {
        let queries: [URLQueryItem] = [
            .init(name: "sort", value: "added"),
            .init(name: "sortDirection", value: "desc"),
            .init(name: "filter", value: "all"),
            .init(name: "mediaType", value: "all")
        ]
        guard let (data, _, _) = try? await SeerSession.shared.raw(Requests.all(page, limit: 10), queries: queries), let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ([], true)
        }

        let results: [[String: Any]]? = json["results"] as? [[String: Any]]

        if results?.isEmpty == false {
            let fetched: [MediaRequest] = results!.map { .init(data: $0) }
            return (fetched, true)
        }
        return ([], true)
    }

    @ViewBuilder
    private func discoverH(_ items: [DiscoverItem]) -> some View {
        #if !os(tvOS)
        let vspacing: CGFloat = 8.0
        #else
        let vspacing: CGFloat = 20.0
        #endif

        HStack(spacing: vspacing) {
            ForEach(items) { i in
				DiscoverItemRow(item: i)
            }
        }
    }

	@ViewBuilder
	private func redactedH(_ duplicates: Int = 10) -> some View {
		#if !os(tvOS)
		let vspacing: CGFloat = 8.0
		#else
		let vspacing: CGFloat = 20.0
		#endif

		HStack(spacing: vspacing) {
			ForEach(Array(repeating: DiscoverItem.redacted, count: duplicates)) { i in
				DiscoverItemRow(item: i)
					.redacted(reason: .placeholder)
			}
		}
	}

	@ViewBuilder
	private func requestsH(_ items: [MediaRequest]) -> some View {
		let vspacing: CGFloat = 8.0

		HStack(spacing: vspacing) {
			ForEach(items) { i in
				RequestRow(i)
					.padding(.vertical, 8)
			}
		}
	}

	@ViewBuilder
	private func redactedReqH(_ duplicates: Int = 5) -> some View {
		let vspacing: CGFloat = 8.0

		HStack(spacing: vspacing) {
			ForEach(Array(repeating: MediaRequest.redacted, count: duplicates)) { i in
				RequestRow(i)
					.padding(.vertical, 8)
					.redacted(reason: .placeholder)
			}
		}
	}
}

#Preview {
    DiscoverView()
}

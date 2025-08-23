// Made by Lumaa

import SwiftUI

struct DiscoverView: View {
    @State private var watchlist: [DiscoverItem] = []
    @State private var requests: [MediaRequest] = []

    @State private var trending: [DiscoverItem] = []

    @State private var movies: [DiscoverItem] = []
    @State private var shows: [DiscoverItem] = []

    @State private var upMovies: [DiscoverItem] = []
    @State private var upShows: [DiscoverItem] = []

    private var hasLoaded: Bool {
        !trending.isEmpty || !movies.isEmpty || !shows.isEmpty
    }

    var body: some View {
        ZStack {
            if hasLoaded {
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 32) {
                            if !self.watchlist.isEmpty {
                                VScrollItems("my.watchlist") {
                                    self.discoverH(self.watchlist)
                                }
                            }

                            if !self.requests.isEmpty {
                                VScrollItems("recent.requests") {
                                    HStack(spacing: 8) {
                                        ForEach(self.requests) { i in
                                            RequestRow(i, showActions: false)
                                                .padding(.vertical, 8)
                                        }
                                    }
                                }
                            }

                            NavigationVScrollItems("trending") {
                                DiscoverItemsView("trending", endpoint: Discover.trending)
                            } content: {
                                self.discoverH(self.trending)
                            }

                            VScrollItems("movies") {
                                self.discoverH(self.movies)
                            }
                            VScrollItems("shows") {
                                self.discoverH(self.shows)
                            }

                            VScrollItems("upcoming.movies") {
                                self.discoverH(self.upMovies)
                            }
                            VScrollItems("upcoming.shows") {
                                self.discoverH(self.upShows)
                            }
                        }
                    }
                    .navigationTitle(Text("discover"))
                    .scrollContentBackground(.hidden)
                    .background {
                        Color.bgPurple.ignoresSafeArea()
                    }
                    .addSettings()
                }
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .task {
            let infolessList: [DiscoverItem] = await self.fetchItems(endpoint: Discover.watchlist)
            self.watchlist = infolessList
            self.requests = await self.fetchRequests()

            self.trending = await self.fetchItems(endpoint: Discover.trending)

            self.movies = await self.fetchItems(endpoint: Discover.movie)
            self.shows = await self.fetchItems(endpoint: Discover.show)

            self.upMovies = await self.fetchItems(endpoint: Discover.movie, queries: [Discover.upcoming(type: .movie)])
            self.upShows = await self.fetchItems(endpoint: Discover.show, queries: [Discover.upcoming(type: .show)])

            for item in infolessList {
                guard var fetchedItem = await item.fetch(), let index = self.watchlist.firstIndex(of: item) else { return }
                fetchedItem.inWatchList = true
                self.watchlist[index] = fetchedItem
            }
        }
    }

    private func fetchItems(endpoint: Discover, queries: [URLQueryItem] = []) async -> [DiscoverItem] {
        guard let (data, _, _) = try? await SeerSession.shared.raw(endpoint, queries: queries), let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }

        let results: [[String: Any]]? = json["results"] as? [[String: Any]]

        if results?.isEmpty == false {
            let fetched: [DiscoverItem] = results!.map { .init(data: $0) }
            return fetched
        }
        return []
    }

    private func fetchRequests(_ page: Int = 1) async -> [MediaRequest] {
        let queries: [URLQueryItem] = [
            .init(name: "sort", value: "added"),
            .init(name: "sortDirection", value: "desc"),
            .init(name: "filter", value: "all"),
            .init(name: "mediaType", value: "all")
        ]
        guard let (data, _, _) = try? await SeerSession.shared.raw(Requests.all(page, limit: 10), queries: queries), let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }

        let results: [[String: Any]]? = json["results"] as? [[String: Any]]

        if results?.isEmpty == false {
            let fetched: [MediaRequest] = results!.map { .init(data: $0) }
            return fetched
        }
        return []
    }

    @ViewBuilder
    private func discoverH(_ items: [DiscoverItem]) -> some View {
        HStack(spacing: 8) {
            ForEach(items) { i in
                DiscoverItemRow(item: i)
            }
        }
    }
}

#Preview {
    DiscoverView()
}

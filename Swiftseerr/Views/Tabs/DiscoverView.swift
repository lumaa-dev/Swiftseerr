// Made by Lumaa

import SwiftUI

struct DiscoverView: View {
    @State private var trending: [DiscoverItem] = []
    @State private var movies: [DiscoverItem] = []
    @State private var shows: [DiscoverItem] = []

    private var hasLoaded: Bool {
        !trending.isEmpty || !movies.isEmpty || !shows.isEmpty
    }

    var body: some View {
        ZStack {
            if hasLoaded {
                NavigationStack {
                    ScrollView {
                        LazyVStack(spacing: 32) {
                            VScrollItems("trending", items: trending)
                            VScrollItems("movies", items: movies)
                            VScrollItems("shows", items: shows)
                        }
                    }
                    .navigationTitle(Text("discover"))
                }
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .task {
            self.trending = await self.fetchTrend()
            self.movies = await self.fetchItems(type: .movie)
            self.shows = await self.fetchItems(type: .show)

        }
    }

    func fetchTrend() async -> [DiscoverItem] {
        guard let (data, _, _) = try? await SeerSession.shared.raw(Discover.trending), let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [] }

        let results: [[String: Any]]? = json["results"] as? [[String: Any]]

        if results?.isEmpty == false {
            let fetched: [DiscoverItem] = results!.map { .init(data: $0) }
            print(fetched)
            return fetched
        }
        return []
    }

    func fetchItems(type: DiscoverItem.ItemType) async -> [DiscoverItem] {
        let endpoint: Discover = type == .movie ? Discover.movie : Discover.show
        guard let (data, _, _) = try? await SeerSession.shared.raw(endpoint), let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [] }

        let results: [[String: Any]]? = json["results"] as? [[String: Any]]

        if results?.isEmpty == false {
            let fetched: [DiscoverItem] = results!.map { .init(data: $0) }
            print(fetched)
            return fetched
        }
        return []
    }

    func fetchUpcoming(type: DiscoverItem.ItemType) async -> [DiscoverItem] {
        let endpoint: Discover = type == .movie ? Discover.movie : Discover.show
        guard let (data, _, _) = try? await SeerSession.shared.raw(endpoint, queries: [Discover.upcoming()]), let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }

        let results: [[String: Any]]? = json["results"] as? [[String: Any]]

        if results?.isEmpty == false {
            let fetched: [DiscoverItem] = results!.map { .init(data: $0) }
            print(fetched)
            return fetched
        }
        return []
    }
}

#Preview {
    DiscoverView()
}

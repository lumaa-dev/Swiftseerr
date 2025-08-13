// Made by Lumaa

import SwiftUI

struct DiscoverItemsView: View {
    let type: ItemType

    @State private var items: [DiscoverItem] = []

    private var endpoint: Discover {
        type == .movie ? .movie : .show
    }

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    init(type: ItemType) {
        self.type = type
    }

    var body: some View {
        ZStack {
            if self.items.isEmpty {
                ProgressView()
                    .progressViewStyle(.circular)
            } else {
                NavigationStack {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(items) { item in
                                DiscoverItemRow(item: item)
                            }
                        }
                        .padding()
                    }
                    .navigationTitle(Text(type == .movie ? "movies" : "shows"))
                    .scrollContentBackground(.hidden)
                    .background {
                        Color.bgPurple.ignoresSafeArea()
                    }
                    .addSettings()
                }
            }
        }
        .task {
            self.items = await self.fetchItems()
        }
    }

    func fetchItems(page: Int = 1) async -> [DiscoverItem] {
        guard let (data, _, _) = try? await SeerSession.shared.raw(self.endpoint, queries: [.init(name: "page", value: "\(page)")]), let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }

        let results: [[String: Any]]? = json["results"] as? [[String: Any]]

        if results?.isEmpty == false {
            let fetched: [DiscoverItem] = results!.map { .init(data: $0) }
            return fetched
        }
        return []
    }
}

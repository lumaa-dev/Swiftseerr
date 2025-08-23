// Made by Lumaa

import SwiftUI

struct DiscoverItemsView: View {
    let title: LocalizedStringKey
    let endpoint: any Endpoint

    @State private var items: [DiscoverItem] = []
    @State private var pages: Int = 2

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    init(_ title: LocalizedStringKey, endpoint: any Endpoint) {
        self.title = title
        self.endpoint = endpoint
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
                                    .onAppear {
                                        guard let lastItem = self.items.last, item == lastItem else { return }

                                        Task {
                                            let newItems: [DiscoverItem] = await self.fetchItems(page: self.pages)
                                            if !newItems.isEmpty {
                                                self.pages += 1
                                                self.items.append(contentsOf: newItems)
                                            } else {
                                                print("[fetchItems (page \(self.pages)] Nothing new to add")
                                            }
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                    .navigationTitle(self.title)
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

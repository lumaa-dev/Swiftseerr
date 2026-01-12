// Made by Lumaa

import SwiftUI

struct DiscoverItemsView: View {
    let title: LocalizedStringKey
    let endpoint: any Endpoint
    let query: [URLQueryItem]

    @State private var items: [DiscoverItem] = []
    @State private var pages: Int = 2

    private var columns: [GridItem] {
        #if canImport(UIKit) && os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return [GridItem(.adaptive(minimum: 200), spacing: 16)]
        } else {
            return Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
        }
        #elseif os(tvOS) || os(macOS)
        return [GridItem(.adaptive(minimum: 200), spacing: 24)]
        #else
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
        #endif
    }

    init(_ title: LocalizedStringKey, endpoint: any Endpoint, additionalQueries: [URLQueryItem] = []) {
        self.title = title
        self.endpoint = endpoint
        self.query = additionalQueries
    }

    var body: some View {
        ZStack {
            if self.items.isEmpty {
                Color.bgPurple
                    .ignoresSafeArea()
                
                ProgressView()
                    .progressViewStyle(.circular)
            } else {
                NavigationStack {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(items) { item in
                                DiscoverItemRow(item: item)
                                    .frame(maxWidth: .infinity)
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
                    #if !os(tvOS)
                    .navigationTitle(self.title)
                    .toolbarTitleDisplayMode(.inlineLarge)
                    .scrollContentBackground(.hidden)
                    #endif
                    .background {
                        Color.bgPurple.ignoresSafeArea()
                    }
                    #if !os(tvOS)
                    .addSettings()
                    #endif
                }
            }
        }
        .task {
            self.items = await self.fetchItems()
        }
    }

    func fetchItems(page: Int = 1) async -> [DiscoverItem] {
        var q: [URLQueryItem] = [.init(name: "page", value: "\(page)")]
        q.append(contentsOf: self.query)

        guard let (data, _, _) = try? await SeerSession.shared.raw(self.endpoint, queries: q), let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }

        let results: [[String: Any]]? = json["results"] as? [[String: Any]]

        if results?.isEmpty == false {
            let viewBlacklist: Bool = SeerSession.shared.user?.hasPermission(Permission.viewBlacklist) ?? false
            
            let fetched: [DiscoverItem] = results!.map { .init(data: $0) }.filter { $0.requestStatus != .blacklisted || viewBlacklist }
            return fetched
        }
        return []
    }
}

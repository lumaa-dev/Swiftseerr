// Made by Lumaa

import SwiftUI

struct SearchView: View {
    @State private var query: String = ""

    @State private var isSearching: Bool = false
    @State private var searchTask: Task<Void, Never>?

    @State private var items: [DiscoverItem] = []

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            if self.items.isEmpty {
                ZStack {
                    if isSearching {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .background {
                                Color.bgPurple.ignoresSafeArea()
                            }
                    } else {
                        ContentUnavailableView.search(text: query)
                            .background {
                                Color.bgPurple.ignoresSafeArea()
                            }
                    }
                }
                .padding()
                .addSettings()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(items) { item in
                            DiscoverItemRow(item: item)
                        }
                    }
                    .padding()
                }
                .navigationTitle("search")
                .scrollContentBackground(.hidden)
                .background {
                    Color.bgPurple.ignoresSafeArea()
                }
                .addSettings()
            }
        }
        .searchable(text: $query, prompt: "search.prompt")
        .onChange(of: query) { _, newQuery in
            searchTask?.cancel()
            self.items = []

            guard !newQuery.isEmpty else { return }

            searchTask = Task {
                guard !searchTask!.isCancelled else { return }

                do {
                    self.isSearching = true
                    guard let (data, _, _) = try? await SeerSession.shared.raw(Search.global(newQuery)), let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw SeerrError() }

                    // Check again before updating UI (in case cancelled during await)
                    guard !searchTask!.isCancelled else { return }

                    await MainActor.run {
                        defer { self.isSearching = false }

                        let results: [[String: Any]]? = json["results"] as? [[String: Any]]

                        if results?.isEmpty == false {
                            let fetched: [DiscoverItem] = results!.compactMap {
                                let type: String = $0["mediaType"] as! String

                                if ["movie", "tv"].contains(type) {
                                    return .init(data: $0)
                                }
                                return nil
                            }
                            withAnimation {
                                self.items = fetched
                            }
                        }
                    }
                } catch {
                    guard !searchTask!.isCancelled else { return }
                    print(error)
                    self.isSearching = false
                }
            }
        }
    }
}

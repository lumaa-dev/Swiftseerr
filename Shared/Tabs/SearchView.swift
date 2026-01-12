// Made by Lumaa

import SwiftUI

struct SearchView: View {
    @State private var query: String = ""

    @State private var isSearching: Bool = false
    @State private var searchTask: Task<Void, Never>?

    @State private var items: [DiscoverItem] = []

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

    var body: some View {
        NavigationStack {
            if self.items.isEmpty {
                ZStack {
                    Color.bgPurple.ignoresSafeArea()
                    
                    if isSearching {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        ContentUnavailableView.search(text: query)
                    }
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(items) { item in
                            DiscoverItemRow(item: item)
                        }
                    }
                    .padding()
                }
                #if !os(tvOS)
                .navigationTitle("search")
                .toolbarTitleDisplayMode(.inlineLarge)
                .scrollContentBackground(.hidden)
                #endif
                .background {
                    Color.bgPurple.ignoresSafeArea()
                }
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
                                    let viewBlacklist: Bool = SeerSession.shared.user?.hasPermission(Permission.viewBlacklist) ?? false
                                    let m: DiscoverItem = .init(data: $0)
                                    
                                    return m.requestStatus != .blacklisted || viewBlacklist ? m : nil
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

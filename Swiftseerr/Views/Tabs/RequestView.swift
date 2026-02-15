// Made by Lumaa

import SwiftUI

struct RequestView: View {
    @State private var requests: [MediaRequest] = []

    @State private var isLoaded: Bool = false

    var body: some View {
        ZStack {
            if isLoaded {
                NavigationStack {
                    ScrollView {
                        LazyVStack {
                            ForEach(self.requests) { req in
                                RequestRow(req) { // onDelete
                                    withAnimation {
                                        self.requests.removeAll(where: { $0.id == req.id })
                                    }
                                }
                            }
                        }
                    }
                    .addSettings()
                    .navigationTitle(Text("requests"))
                    .toolbarTitleDisplayMode(.inlineLarge)
                    .scrollContentBackground(.hidden)
                    .background {
                        Color.bgPurple.ignoresSafeArea()
                    }
                }
            } else {
                Color.bgPurple
                    .ignoresSafeArea()

                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .task {
            await self.load()
        }
        .refreshable {
			self.requests = []
            await self.load()
        }
    }

    private func load() async {
        defer { self.isLoaded = true }
        self.isLoaded = false

        self.requests = await self.fetchRequests()
    }

    func fetchRequests(_ page: Int = 1) async -> [MediaRequest] {
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
}

#Preview {
    RequestView()
}

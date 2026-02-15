// Made by Lumaa

import SwiftUI

struct RequestView: View {
    @State private var requests: [MediaRequest] = []
	@State private var pages: Int = 2

    @State private var isLoaded: Bool = false
	@State private var atBottom: Bool = false

    var body: some View {
        ZStack {
            if isLoaded {
				self.view
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
			self.atBottom = false
            await self.load()
        }
    }

	private var view: some View {
		NavigationStack {
			ScrollView {
				LazyVStack {
					ForEach(self.requests) { req in
						RequestRow(req) { // onDelete
							withAnimation {
								self.requests.removeAll(where: { $0 == req })
							}
						}
						.onAppear {
							guard let lastReq = self.requests.last, req == lastReq, !self.atBottom else { return }

							Task {
								let newItems: [MediaRequest] = await self.fetchRequests(page: self.pages)
								if !newItems.isEmpty {
									self.pages += 1
									self.requests.append(contentsOf: newItems)
								} else {
									print("[fetchRequests (page \(self.pages)] Nothing new to add")
									self.atBottom = true
								}
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
	}

    private func load() async {
        defer { self.isLoaded = true }
        self.isLoaded = false

        self.requests = await self.fetchRequests()
    }

    func fetchRequests(page: Int = 1) async -> [MediaRequest] {
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

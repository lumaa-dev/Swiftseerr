// Made by Lumaa

import SwiftUI

struct RequestView: View {
    @State private var requests: [MediaRequest] = []
	@State private var pages: Int = 2

	@State private var activeFilter: Self.Filters = .all

    @State private var isLoaded: Bool = false
	@State private var atBottom: Bool = false

    var body: some View {
		NavigationStack {
			ScrollView {
				if self.isLoaded && !self.requests.isEmpty  {
					LazyVStack {
						ForEach(self.requests) { req in
							let index: Int? = self.requests.firstIndex(of: req)

							RequestRow(Binding(get: { req }, set: { self.requests[index!] = $0 })) { // onDelete
								withAnimation {
									self.requests.removeAll(where: { $0 == req })
								}
							}
							.onAppear {
								guard let lastReq = self.requests.last, req == lastReq, !self.atBottom else { return }

								Task {
									let newItems: [MediaRequest] = await self.fetchRequests(
										page: self.pages,
										filter: self.activeFilter
									)

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
				} else if !self.isLoaded {
					ProgressView()
						.progressViewStyle(.circular)
						.frame(maxWidth: .infinity)
				} else if self.isLoaded && self.requests.isEmpty {
					ContentUnavailableView("no.requests", systemImage: "clock.badge.questionmark", description: Text("no.requests.description"))
				}
			}
			.addSettings()
			.navigationTitle(Text("requests"))
			.toolbarTitleDisplayMode(.inlineLarge)
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Menu {
						Picker("requests.filter", selection: $activeFilter) {
							ForEach(Self.Filters.allCases, id: \.self) { filter in
								Text(filter.localized)
									.tag(filter)
							}
						}
					} label: {
						Label("requests.filter", systemImage: "line.3.horizontal.decrease")
					}
				}
			}
			.scrollContentBackground(.hidden)
			.background {
				Color.bgPurple.ignoresSafeArea()
			}
			.onChange(of: self.activeFilter) { _, newValue in
				Task {
					await self.load()
				}
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

    private func load() async {
        defer { self.isLoaded = true }
        self.isLoaded = false
		self.pages = 2
		self.atBottom = false

		self.requests = await self.fetchRequests(filter: self.activeFilter)
		print("loaded \(requests.count) requests")
    }

	func fetchRequests(page: Int = 1, filter: Self.Filters = .all) async -> [MediaRequest] {
        let queries: [URLQueryItem] = [
            .init(name: "sort", value: "added"),
            .init(name: "sortDirection", value: "desc"),
			.init(name: "filter", value: filter.rawValue),
            .init(name: "mediaType", value: "all")
        ]

		let endpoint = Requests.all(page, limit: 10)

		do {
			let (data, _, _) = try await Task.detached {
				try await SeerSession.shared.raw(endpoint, queries: queries)
			}.value

			guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
				  let results = json["results"] as? [[String: Any]],
				  !results.isEmpty else {
				return []
			}

			return results.map { .init(data: $0) }
		} catch {
			if let urlError = error as? URLError, urlError.code == .cancelled {
				print("[fetchRequests] Cancelled (normal during refresh)")
				return []
			}

			print("[fetchRequests] Error: \(error.localizedDescription)")
			return []
		}
    }

	/// Can be found [here](https://github.com/seerr-team/seerr/blob/develop/server/routes/request.ts#L45-L104). Kept only the essentials
	enum Filters: String, CaseIterable {
		case all = "all"
		case available = "available"
		case pending = "pending"
		case processing = "processing"
		case failed = "failed"
		case deleted = "deleted"

		var localized: String {
			switch self {
				case .all:
					String(localized: "request.filter.all")
				case .available:
					String(localized: "request.filter.available")
				case .pending:
					String(localized: "request.filter.pending")
				case .processing:
					String(localized: "request.filter.processing")
				case .failed:
					String(localized: "request.filter.failed")
				case .deleted:
					String(localized: "request.filter.deleted")
			}
		}
	}
}

#Preview {
    RequestView()
}

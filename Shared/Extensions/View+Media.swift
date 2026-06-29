// Made by Lumaa

import SwiftUI

extension View {
    @ViewBuilder
    func mediaContext(_ item: DiscoverItem) -> some View {
        self
            .contextMenu {
                Button {
                    Task {
                        await self.changeWatchlist(item)
                    }
                } label: {
                    Label(item.inWatchList ? "remove.watchlist" : "add.watchlist", systemImage: item.inWatchList ? "star.fill" : "star")
                }

                Section("request") {
                    Button {
                        Task {
                            await self.request(item)
                        }
                    } label: {
                        Label("request.hd", systemImage: "tray.and.arrow.down")
                    }
                    .disabled(item.requestStatus != .unknown)

                    Button {
                        Task {
							await self.request(item, is4k: true)
                        }
                    } label: {
                        Label("request.4k", systemImage: "4k.tv")
                    }
                    .disabled(item.requestStatus != .unknown)
                }
            }
    }

    @ViewBuilder
    func mediaContext(media: MediaItem) -> some View {
        self
            .mediaContext(media.toDiscover())
    }

    private func request(_ item: DiscoverItem, is4k: Bool = false) async -> HTTPURLResponse? {
		if item.type == .movie {
			let http: HTTPURLResponse? = try? await SeerSession.shared.raw(Requests.create(id: item.id, type: item.type, is4k: is4k)).1
			return http
		} else if item.type == .show {
			guard let media: MediaItem = try? await self.fetchItem(item), media.seasons.count > 0 else { return nil }

			var http: HTTPURLResponse? = nil
			Navigator.shared.presentedSheet = .seasonsPicker(media.seasons, disabledSeasons: Array(media.availableSeasons.keys)) { selection in
					http = await self.selectionSeasons(media, is4k: is4k, with: selection)
				}

			return http
		}
		
		return nil
    }

	private func selectionSeasons(_ item: MediaItem, is4k: Bool = false, with seasons: [ShowSeason.About] = []) async -> HTTPURLResponse? {
		let http: HTTPURLResponse? = try? await SeerSession.shared.raw(Requests.create(id: item.id, type: item.type, is4k: is4k, seasons: seasons.map { $0.seasonNumber })).1
		return http
	}

	private func fetchItem(_ item: DiscoverItem) async throws -> MediaItem {
		let (data, res, _) = try await SeerSession.shared.raw(Media.get(id: item.id, type: item.type))
		let code = res?.statusCode ?? -1

		if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], code == 200 {
			return .init(data: json, type: item.type)
		}
		throw SeerrError()
	}

    private func changeWatchlist(_ item: DiscoverItem) async -> HTTPURLResponse? {
		let endpoint: Watchlist = item.inWatchList ? .remove(tmdbId: item.id, type: item.type) : .add(tmdbId: item.id, type: item.type, name: item.name)
        let http: HTTPURLResponse? = try? await SeerSession.shared.raw(endpoint).1
        return http
    }
}

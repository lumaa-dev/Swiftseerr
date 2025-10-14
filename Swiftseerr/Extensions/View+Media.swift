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
                            await self.request(item)
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
        let http: HTTPURLResponse? = try? await SeerSession.shared.raw(Requests.create(id: item.id, type: item.type, is4k: is4k)).1
        return http
    }

    private func changeWatchlist(_ item: DiscoverItem) async -> HTTPURLResponse? {
        let endpoint: Watchlist = item.inWatchList ? .remove(tmdbId: item.id) : .add(tmdbId: item.id, type: item.type, name: item.name)
        let http: HTTPURLResponse? = try? await SeerSession.shared.raw(endpoint).1
        return http
    }
}

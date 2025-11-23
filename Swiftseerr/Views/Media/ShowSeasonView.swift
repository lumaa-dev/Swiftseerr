// Made by Lumaa

import SwiftUI

struct ShowSeasonView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction

    let item: MediaItem
    let aboutSeason: ShowSeason.About

    @State private var season: ShowSeason? = nil
    @State private var isLoading: Bool = true

    init(item: MediaItem, season: ShowSeason.About) {
        self.item = item
        self.aboutSeason = season
    }

    init(item: MediaItem, using season: ShowSeason) {
        self.item = item
        self.aboutSeason = .init(from: season)
        self.season = season
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if self.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let season {
                    ScrollView {
                        LazyVStack(alignment: .center, spacing: 15.0) {
                            ForEach(season.episodes) { episode in
                                self.episodeView(episode)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    ContentUnavailableView("no.season", systemImage: "rectangle.stack.slash")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(Text(self.aboutSeason.name))
            .navigationSubtitle(Text("show.episodes-\(self.aboutSeason.episodeNumber)"))
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background {
                Color.bgPurple.ignoresSafeArea()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) {
                        self.dismiss()
                    }
                }
            }
            .task {
                defer { self.isLoading = false }
                guard self.season == nil else { return }

                self.season = try? await self.fetchSeason()
            }
        }
    }

    @ViewBuilder
    private func episodeView(_ episode: ShowEpisode) -> some View {
        AsyncImage(url: episode.posterPath) { image in
            image
                .resizable()
                .scaledToFill()
                .aspectRatio(16/9, contentMode: .fit)
                .frame(width: 375)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } placeholder: {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.gradient)
                .aspectRatio(16/9, contentMode: .fit)
                .frame(width: 375)
                .overlay {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
        }
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading) {
                Text(episode.name)
                    .font(.body.bold())
                    .lineLimit(1)

                if !episode.summary.isEmpty {
                    Text(episode.summary)
                        .font(.caption)
                        .lineLimit(3)
                }
            }
            .padding(10.0)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 15.0))
            .padding()
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 7.5) {
                if let date: Date = episode.airDate {
                    Text(date, format: .dateTime.day(.defaultDigits).month(.wide).year(.extended(minimumLength: 4)))
                        .font(.callout)

                    Text(String("–"))
                        .font(.callout)
                }

                Text(episode.asEpisode, format: .number)
                    .font(.callout.bold())
            }
            .padding(10.0)
            .glassEffect(.clear.tint(Color.accentPurple.opacity(0.7)), in: Capsule())
            .padding()
        }
        .frame(width: 375, alignment: .center)
    }

    private func fetchSeason() async throws -> ShowSeason {
        let (data, res, _) = try await SeerSession.shared.raw(Media.season(item: self.item, season: self.aboutSeason))
        let code = res?.statusCode ?? -1

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], code == 200 {
            return .init(data: json)
        }
        throw SeerrError()
    }
}

// Made by Lumaa

import SwiftUI

struct MediaItemView: View {
    @State private var item: MediaItem? = nil

    @State private var isLoading: Bool = false

    let id: Int
    let type: ItemType

    private var posterWidth: CGFloat { self.posterHeight * (1.0 / 1.5) }
    private let posterHeight: CGFloat = 260

    init(item: MediaItem) {
        self.item = item
        self.id = item.id
        self.type = item.type
    }

    init(mediaId: Int, type: ItemType) {
        self.id = mediaId
        self.type = type
    }

    var body: some View {
        ScrollView {
            if let item {
                VStack {
                    header

                    info
                }
                .navigationTitle(Text(item.title))
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .ignoresSafeArea(edges: .top)
        .task {
            if let newItem = try? await self.fetchItem() {
                self.item = newItem
            }
        }
    }

    private var header: some View {
        ZStack(alignment: .top) {
            AsyncImage(url: item?.backdrop) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                EmptyView()
            }
            .frame(height: 400, alignment: .center)
            .mask {
                LinearGradient(colors: [Color.white.opacity(0.75), Color.clear], startPoint: .top, endPoint: .bottom)
            }

            AsyncImage(url: item?.image) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: self.posterWidth, height: self.posterHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.gradient)
                    .frame(width: self.posterWidth, height: self.posterHeight)
                    .overlay {
                        Text(String("?"))
                            .font(.system(size: 176, weight: .ultraLight, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
            }
            .safeAreaPadding(.top, 120)
        }
    }

    private var info: some View {
        VStack(alignment: .leading) {
            Text(self.item!.title)
                .font(.title2.bold())
                .multilineTextAlignment(.leading)

            Text(self.item!.tagline)
                .foregroundStyle(Color.secondary)
                .font(.callout.width(.condensed))
                .multilineTextAlignment(.leading)

            GlassEffectContainer {
                HStack {
                    if self.item!.requestStatus == .requestable || self.item!.requestStatus == .unknown {
                        Button {
                            Task {
                                if let http: HTTPURLResponse = await self.request(), http.statusCode == 201 {
                                    withAnimation {
                                        self.item!.requestStatus = .pending
                                    }
                                }
                            }
                        } label: {
                            Text("request")
                        }
                        .buttonStyle(.glassProminent)

                        Button {
                            Task {
                                if let http: HTTPURLResponse = await self.request(is4k: true), http.statusCode == 201 {
                                    withAnimation {
                                        self.item!.requestStatus = .pending
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "4k.tv")
                        }
                        .frame(maxHeight: .infinity)
                        .buttonStyle(.glass)
                    } else {
                        Text(self.item!.requestStatus.localized)
                            .padding(7.0)
                            .glassEffect(.regular.interactive(false).tint(self.item!.requestStatus.color.opacity(0.4)))
                    }
                }
            }
            .frame(width: 370, alignment: .center)

            Text("summary")
                .font(.title.bold())
                .padding(.top, 20)

            Text(self.item!.overview)
                .font(.body.italic())
                .multilineTextAlignment(.leading)
        }
        .frame(width: 370, alignment: .leading)
    }

    private func fetchItem() async throws -> MediaItem {
        guard self.item == nil else { throw SeerrError() }

        let (data, res, _) = try await SeerSession.shared.raw(Media.get(id: self.id, type: self.type))
        let code = res?.statusCode ?? -1

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], code == 200 {
            return .init(data: json, type: self.type)
        }
        throw SeerrError()
    }

    private func request(is4k: Bool = false) async -> HTTPURLResponse? {
        guard let item else { return nil }

        let http: HTTPURLResponse? = try? await SeerSession.shared.raw(Requests.create(id: item.id, type: item.type, is4k: is4k)).1
        return http
    }
}

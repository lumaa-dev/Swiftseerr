// Made by Lumaa

import SwiftUI

struct MediaItemView: View {
    @State private var item: MediaItem? = nil

    let id: Int
    let type: ItemType

    private var posterWidth: CGFloat { self.posterHeight * (1.0 / 1.5) }
    private let posterHeight: CGFloat = 260

    private var canManageRequests: Bool {
        guard let user = SeerSession.shared.user else { return false }
        return user.hasPermission(Permission.manageRequests)
    }

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

                    list
                        .padding(.top, 30.0)
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
        VStack(alignment: .leading, spacing: 25) {
            GlassEffectContainer {
                HStack {
                    if self.item!.requestStatus == .unknown {
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
                        .buttonBorderShape(.circle)
                        .buttonStyle(.glass)
                    } else {
                        Text(self.item!.requestStatus.localized)
                            .padding(.vertical, 7.0)
                            .padding(.horizontal, 15.0)
                            .glassEffect(.regular.interactive(false).tint(self.item!.requestStatus.color.opacity(0.4)))

                        Menu {
                            if canManageRequests {
                                ForEach(self.item!.requests) { req in
                                    Menu {
                                        if self.canManageRequests {
                                            self.manageRequest(req)
                                        }

                                        Button(role: .destructive) {
                                            Task {
                                                if let http = await self.deleteRequest(req), http.statusCode == 204 {
                                                    let newItem = try? await self.fetchItem()
                                                    await MainActor.run {
                                                        withAnimation{
                                                            self.item = newItem
                                                        }
                                                    }
                                                }
                                            }
                                        } label: {
                                            Label("request.delete", systemImage: "trash")
                                        }
                                    } label: {
                                        Text("request.by-\(req.requestedBy.username)")
                                    }
                                }
                            } else if let req: MediaRequest = self.item!.requests.filter({ $0.requestedBy == SeerSession.shared.user }).first {
                                Button(role: .destructive) {
                                    Task {
                                        if let http = await self.deleteRequest(req), http.statusCode == 204 {
                                            let newItem = try? await self.fetchItem()
                                            await MainActor.run {
                                                withAnimation{
                                                    self.item = newItem
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    Label("request.delete", systemImage: "trash")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundStyle(Color.primary)
                                .padding(10.0)
                                .glassEffect(.regular.interactive())
                        }
                        .menuStyle(.borderlessButton)
                    }
                }
            }
            .frame(width: 370, alignment: .center)

            VStack(alignment: .leading) {
                Text(self.item!.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.leading)

                Text(self.item!.tagline)
                    .foregroundStyle(Color.secondary)
                    .font(.callout.width(.condensed))
                    .multilineTextAlignment(.leading)
            }

            if !self.item!.overview.isEmpty {
                VStack(alignment: .leading) {
                    Text("summary")
                        .font(.title2.bold())

                    Text(self.item!.overview)
                        .font(.body.italic())
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .frame(width: 370, alignment: .leading)
    }

    @ViewBuilder
    private var list: some View {
        VStack(spacing: 20.0) {
            HStack {
                Text("release")

                Spacer()

                Text(self.item!.releaseDate, format: .dateTime.day().month(.wide).year(.extended(minimumLength: 4)))
                    .foregroundStyle(Color.secondary)
            }

            if let duration = self.item!.runtime, duration > 0 {
                Divider()

                HStack {
                    Text("duration")

                    Spacer()

                    Text("duration.m-\(duration)")
                        .foregroundStyle(Color.secondary)
                }
            } else if let seasonsCount = self.item!.seasonsCount, let episodesCount = self.item!.episodesCount {
                Divider()

                HStack {
                    Text("duration")

                    Spacer()

                    Text("show.seasons-\(seasonsCount).episodes-\(episodesCount)")
                        .foregroundStyle(Color.secondary)
                }
            }

            if let rating = self.item!.rating {
                Divider()

                HStack {
                    Text("content-rating")

                    Spacer()

                    Text(rating)
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .frame(width: 340, alignment: .leading)
        .padding(.vertical)
        .padding(.horizontal, 15.0)
        .background(Color(uiColor: UIColor.tertiarySystemBackground).opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 15.0))
    }

    // MARK: View Methods

    @ViewBuilder
    private func manageRequest(_ request: MediaRequest) -> some View {
        ControlGroup {
            Button {
                Task {
                    if let http = await self.updateStatus(.approve, request: request), http.statusCode == 200 {
                        let newItem = try? await self.fetchItem()
                        await MainActor.run {
                            withAnimation {
                                self.item = newItem
                            }
                        }
                    }
                }
            } label: {
                Label("request.accept", systemImage: "checkmark")
            }

            Button {
                Task {
                    if let http = await self.updateStatus(.decline, request: request), http.statusCode == 200 {
                        let newItem = try? await self.fetchItem()
                        await MainActor.run {
                            withAnimation {
                                self.item = newItem
                            }
                        }
                    }
                }
            } label: {
                Label("request.decline", systemImage: "xmark")
            }
        }
    }

    // MARK: Functional Methods

    private func fetchItem() async throws -> MediaItem {
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

    private func updateStatus(_ status: Requests.Status, request: MediaRequest) async -> HTTPURLResponse? {
        let http: HTTPURLResponse? = try? await SeerSession.shared.raw(Requests.updateStatus(id: request.id, status: status)).1
        return http
    }

    private func deleteRequest(_ request: MediaRequest) async -> HTTPURLResponse? {
        let http: HTTPURLResponse? = try? await SeerSession.shared.raw(Requests.delete(id: request.id)).1
        return http
    }

    func flagEmoji(for regionCode: String) -> String? {
        guard regionCode.count == 2, let asciiA = Character("A").asciiValue else { return nil }

        let uppercasedCode = regionCode.uppercased()
        var emoji = ""

        for char in uppercasedCode {
            guard let asciiValue = char.asciiValue, let z = Character("Z").asciiValue, asciiValue >= asciiA && asciiValue <= z else { return nil }
            let offset = UInt32(asciiValue - asciiA)
            if let scalar = UnicodeScalar(0x1F1E6 + offset) {
                emoji.append(Character(scalar))
            } else {
                return nil
            }
        }

        return emoji
    }
}

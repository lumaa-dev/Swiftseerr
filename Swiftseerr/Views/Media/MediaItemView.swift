// Made by Lumaa

import SwiftUI
import DeclaredAgeRange

struct MediaItemView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @Environment(\.requestAgeRange) private var requestAgeRange: DeclaredAgeRangeAction

    @State private var item: MediaItem? = nil
    @State private var loadedData: Bool = false
    @State private var hideContent: Bool = false

    @State private var showingSeason: ShowSeason.About? = nil

    // requesting seasons
    @State private var requestingSeason: Bool = false
    @State private var requestingSeason4k: Bool = false

    @State private var errorAlert: Bool = false
    @State private var errorString: String? = nil

    let id: Int
    let type: ItemType

    private var posterWidth: CGFloat { self.posterHeight * (1.0 / 1.5) }
    private let posterHeight: CGFloat = 260

    private var canManageRequests: Bool {
        guard let user = SeerSession.shared.user else { return false }
        return user.hasPermission(Permission.manageRequests)
    }

    init(_ item: MediaItem) {
        self.item = item
        self.id = item.id
        self.type = item.type
        self.loadedData = true
    }

    init(mediaId: Int, type: ItemType) {
        self.item = .redacted
        self.id = mediaId
        self.type = type
    }

    var body: some View {
        ScrollView {
            if let item {
                VStack {
                    header

                    info

                    seasons
                        .padding(.vertical, 15.0)

                    castCrew
                        .padding(.vertical, 15.0)

                    list
                        .padding(.vertical, 15.0)
                }
                .navigationTitle(Text(self.loadedData ? item.title : String("")))
                .navigationBarTitleDisplayMode(.inline)
                .sheet(item: $showingSeason) { season in
                    ShowSeasonView(item: item, season: season)
                }
                .sheet(isPresented: $requestingSeason) {
                    SeasonsPicker(seasons: item.seasons, disabledSeasons: Array(item.availableSeasons.keys)) { selection in
                        await self.requestButton(is4k: self.requestingSeason4k, with: selection)
                    }
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.hidden)
                    .presentationBackground(Color.bgPurple)
                }
                .toolbar {
                    ToolbarItem {
                        Button {
                            withAnimation {
                                self.item!.inWatchList.toggle()
                            }

                            Task {
                                let http: HTTPURLResponse? = await self.changeWatchlist()
                                if let http, !(http.statusCode >= 200 && http.statusCode <= 208) {
                                    self.item!.inWatchList.toggle()
                                } else if http == nil {
                                    self.item!.inWatchList.toggle()
                                }
                            }
                        } label: {
                            Label(item.inWatchList ? "remove.watchlist" : "add.watchlist", systemImage: item.inWatchList ? "star.fill" : "star")
                                .contentTransition(.symbolEffect(.replace.downUp))
                        }
                        .disabled(self.hideContent || !self.loadedData)
                    }


                    ToolbarItem {
                        Menu {
                            Button {
                                withAnimation {
                                    self.item!.inWatchList.toggle()
                                }

                                Task {
                                    let http: HTTPURLResponse? = await self.changeWatchlist()
                                    if let http, !(http.statusCode >= 200 && http.statusCode <= 208) {
                                        self.item!.inWatchList.toggle()
                                    } else if http == nil {
                                        self.item!.inWatchList.toggle()
                                    }
                                }
                            } label: {
                                Label(item.inWatchList ? "remove.watchlist" : "add.watchlist", systemImage: item.inWatchList ? "star.fill" : "star")
                                    .contentTransition(.symbolEffect(.replace.downUp))
                            }
                            .disabled(self.hideContent || !self.loadedData)

                            Divider()

                            if let jellyfin = item.jellyfin {
                                Link(destination: jellyfin) {
                                    Label("open.jellyfin", image: .jellyfin)
                                }
                            }

                            if let webUrl = item.webUrl {
                                ShareLink(item: webUrl)
                            }
                        } label: {
                            Label("more-actions", systemImage: "ellipsis")
                        }
                        .disabled(self.hideContent || !self.loadedData)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background {
            Color.bgPurple.ignoresSafeArea()
        }
        .ignoresSafeArea(edges: .top)
        .task {
            if let newItem = try? await self.fetchItem() {
                self.item = newItem
                self.loadedData = true
                await self.verifyAge()
            }
        }
        .alert("error", isPresented: $errorAlert) {
            Button(role: .cancel) {
                self.dismiss()
            }
        } message: {
            Text(errorString ?? "error.unknown")
        }
    }

    @ViewBuilder
    private var header: some View {
        ZStack(alignment: .top) {
            AsyncImage(url: item?.backdrop) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .blur(radius: self.hideContent ? 8.0 : 0)
            } placeholder: {
                Rectangle()
                    .fill(Color.bgPurple)
            }
            .frame(height: 400, alignment: .center)
            .mask {
                LinearGradient(colors: [Color.white.opacity(0.75), Color.clear], startPoint: .top, endPoint: .bottom)
            }

            let imgUrl: URL? = self.loadedData ? item?.image ?? URL(string: "\(SeerSession.shared.auth.address)/images/jellyseerr_poster_not_found.png") : item?.image

            AsyncImage(url: imgUrl) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: self.posterWidth, height: self.posterHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.clear)
                    .frame(width: self.posterWidth, height: self.posterHeight)
                    .overlay {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
            }
            .safeAreaPadding(.top, 120)
        }
        .stretchy()
    }

    @ViewBuilder
    private var info: some View {
        VStack(alignment: .leading, spacing: 25) {
            GlassEffectContainer {
                HStack {
                    if self.item!.requestStatus == .unknown || self.item!.requestStatus == .partiallyAvailable {
                        Button {
                            Task {
                                if self.item!.type == .movie || self.item!.seasons.count <= 1 {
                                    await self.requestButton(is4k: false, with: self.item!.seasons.count == 1 ? [self.item!.seasons[0]] : [])
                                } else {
                                    self.requestingSeason.toggle()
                                    self.requestingSeason4k = false
                                }
                            }
                        } label: {
                            Text("request")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(self.hideContent || !self.loadedData)

                        Button {
                            Task {
                                if self.item!.type == .movie || self.item!.seasons.count <= 1 {
                                    await self.requestButton(is4k: true, with: self.item!.seasons.count == 1 ? [self.item!.seasons[0]] : [])
                                } else {
                                    self.requestingSeason.toggle()
                                    self.requestingSeason4k = true
                                }
                            }
                        } label: {
                            Image(systemName: "4k.tv")
                        }
                        .disabled(self.hideContent || !self.loadedData)
                        .buttonBorderShape(.circle)
                        .buttonStyle(.bordered)
                    } else {
                        Text(self.item!.requestStatus.localized)
                            .foregroundStyle(Color.white)
                            .pill(self.item!.requestStatus.color)

                        if self.item!.requests.filter({ $0.requestedBy == SeerSession.shared.user }).first != nil || canManageRequests {
                            Menu {
                                if let jellyfin = self.item!.jellyfin, self.item!.requestStatus == .available {
                                    Link(destination: jellyfin) {
                                        Label("open.jellyfin", image: .jellyfin)
                                    }
                                }

                                if canManageRequests {
                                    ForEach(self.item!.requests.filter { $0.status != .partiallyAvailable || $0.status != .available }) { req in
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
                                                    withAnimation {
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
                                    .padding(7.0)
                            }
                            .menuStyle(.button)
                            .buttonBorderShape(.circle)
                            .disabled(self.hideContent || !self.loadedData)
                        } else {
                            if let jellyfin = self.item!.jellyfin, self.item!.requestStatus == .available {
                                Link(destination: jellyfin) {
                                    Label("open.jellyfin", image: .jellyfin)
                                        .labelStyle(.iconOnly)
                                        .padding(.leading, 5)
                                }
                            }
                        }
                    }
                }
            }
            .frame(width: 370, alignment: .center)

            VStack(alignment: .leading) {
                Text(self.item!.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.leading)
                    .shouldRedact(!self.loadedData)

                Text(self.item!.tagline)
                    .foregroundStyle(Color.secondary)
                    .font(.callout.width(.condensed))
                    .multilineTextAlignment(.leading)
                    .shouldRedact(self.hideContent || !self.loadedData)
            }

            if !self.item!.overview.isEmpty {
                VStack(alignment: .leading) {
                    Text("summary")
                        .font(.title2.bold())

                    Text(self.item!.overview)
                        .font(.body.italic())
                        .multilineTextAlignment(.leading)
                        .shouldRedact(self.hideContent || !self.loadedData)
                }
            }
        }
        .frame(width: 370, alignment: .leading)
    }

    @ViewBuilder
    private var list: some View {
        VStack(spacing: 17.0) {
            LabeledContent(String(localized: "release"), value: self.item!.releaseDate, format: .dateTime.day().month(.wide).year(.extended(minimumLength: 4)))
                .shouldRedact(!self.loadedData)

            if let duration = self.item!.runtime, duration > 0 {
                Divider()

                LabeledContent("duration", value: String(localized: "duration.m-\(duration)"))
                    .shouldRedact(!self.loadedData)
            } else if let seasonsCount = self.item!.seasonsCount, let episodesCount = self.item!.episodesCount {
                Divider()

                LabeledContent("duration", value: String(localized: "show.seasons-\(seasonsCount).episodes-\(episodesCount)"))
                    .shouldRedact(!self.loadedData)
            }

            if let rating = self.item!.rating, !rating.isEmpty {
                Divider()

                LabeledContent("content-rating", value: rating)
                    .shouldRedact(!self.loadedData)
            }
        }
        .frame(width: 340, alignment: .leading)
        .padding(.vertical)
        .padding(.horizontal, 15.0)
//        .background(Color(uiColor: UIColor.tertiarySystemBackground).opacity(0.4))
        .background(Material.ultraThin)
        .clipShape(RoundedRectangle(cornerRadius: 15.0))
    }

    @ViewBuilder
    private var seasons: some View {
        if let item, !item.seasons.isEmpty {
            VStack(alignment: .leading) {
                ForEach(item.seasons.sorted { $0.seasonNumber < $1.seasonNumber }) { season in
                    Button {
                        self.showingSeason = season
                    } label: {
                        HStack {
                            Text(season.name)
                                .foregroundStyle(Color.primary)
                                .font(.title2.bold())
                                .multilineTextAlignment(.leading)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if let s = item.availableSeasons.filter({ $0.key == season.seasonNumber }).first {
                                Text(s.value.localized)
                                    .font(.callout)
                                    .foregroundStyle(Color.white)
                                    .lineLimit(1)
                                    .pill(s.value.color, multiply: 0.7)
                            }

                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(Color.secondary.opacity(0.5))
                                .font(.callout)
                        }
                        .padding(10.0)
                        .background(Material.ultraThin)
                        .clipShape(Capsule())
                        .padding(.horizontal)
                        .shouldRedact(self.hideContent || !self.loadedData)
                    }
                    .disabled(self.hideContent || !self.loadedData)
                }
            }
            .frame(width: 395, alignment: .leading)
        }
    }

    @ViewBuilder
    private var castCrew: some View {
        if let item {
            VStack(alignment: .leading, spacing: 32) {
                if !item.cast.isEmpty {
                    NavigationVScrollItems("cast", destination: MediaPersonsView(with: item.cast, title: "cast")) {
                        HStack {
                            if item.cast.count > 8 {
                                ForEach(item.cast[0...8]) { c in
                                    PersonPlate(c)
                                }
                            } else {
                                ForEach(item.cast) { c in
                                    PersonPlate(c)
                                }
                            }
                        }
                    }
                }

                if !item.crew.isEmpty {
                    NavigationVScrollItems("crew", destination: MediaPersonsView(with: item.crew, title: "crew")) {
                        HStack {
                            if item.crew.count > 8 {
                                ForEach(item.crew[0...8]) { c in
                                    PersonPlate(c)
                                }
                            } else {
                                ForEach(item.crew) { c in
                                    PersonPlate(c)
                                }
                            }
                        }
                    }
                }
            }
            .frame(width: 395, alignment: .leading)
        }
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
            .disabled(request.status != .unknown)

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
            .disabled(request.status != .unknown)
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

    private func verifyAge() async {
        guard let item, let minAge: Int = MediaRating.find(for: item) else { return }

        if #available(iOS 26.2, *) {
            let eligibility: Bool = (try? await AgeRangeService.shared.isEligibleForAgeFeatures) ?? true
            if !eligibility {
                self.hideContent = false
                return
            }
        }

        if MediaRating.prepareAsk(for: minAge) {
            print("[verifyAge] Hiding content, asking for \(minAge)+ age")
#if !targetEnvironment(simulator)
            self.hideContent = true
            
            do {
                let response = try await requestAgeRange(ageGates: minAge)
                
                switch response {
                    case .declinedSharing:
                        print("[verifyAge] Declined age verification")
                        self.hideContent = true // double "true" just in case
                        throw SeerrError()
                    case let .sharing(range):
                        if let lowerBound = range.lowerBound, lowerBound >= minAge {
                            print("[verifyAge] Verified age perfectly")
                            self.hideContent = false
                        }
                    @unknown default:
                        print("[verifyAge] Default case :(")
                        self.hideContent = true
                        throw SeerrError()
                }
            } catch {
                print(error.localizedDescription)
                
                self.errorString = error.localizedDescription
                self.errorAlert = true
            }
#endif
        }
    }

    private func request(is4k: Bool = false, with seasons: [ShowSeason.About] = []) async -> HTTPURLResponse? {
        guard let item else { return nil }

        let http: HTTPURLResponse? = try? await SeerSession.shared.raw(Requests.create(id: item.id, type: item.type, is4k: is4k, seasons: seasons.map { $0.seasonNumber })).1
        return http
    }

    private func requestButton(is4k: Bool = false, with seasons: [ShowSeason.About] = []) async {
        guard let item else { return }

        let canRequest: Bool = item.type == .movie || (item.type == .show && !seasons.isEmpty)

        if canRequest, let http: HTTPURLResponse = await self.request(is4k: is4k, with: seasons), http.statusCode == 201 {
            let typedPermission: Permission = item.type == .movie ? Permission.autoApproveMovie : Permission.autoApproveTV
            let nextState: MediaStatus = SeerSession.shared.user?.hasPermission(
                [Permission.autoApprove, typedPermission],
                options: .or
            ) ?? false ? .processing : .pending

            withAnimation {
                self.item!.requestHd = nextState
            }
        }
    }

    private func changeWatchlist() async -> HTTPURLResponse? {
        guard let item else { return nil }

        let endpoint: Watchlist = !item.inWatchList ? .remove(tmdbId: item.id) : .add(tmdbId: item.id, type: item.type, name: item.title)
        let http: HTTPURLResponse? = try? await SeerSession.shared.raw(endpoint).1
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

private extension View {
    @ViewBuilder
    func shouldRedact(_ redact: Bool = true) -> some View {
        if redact {
            self.redacted(reason: .placeholder)
        } else {
            self
        }
    }
}

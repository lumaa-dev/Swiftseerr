
// Made by Lumaa

import SwiftUI

struct SeerrPersonView: View {
    @State private var  person: SeerrPerson?
    private let personId: Int

    @State private var loadedData: Bool = false
    @State private var shortenedBio: Bool = true

    @State private var personContent: [DiscoverItem] = []

    private var posterWidth: CGFloat { self.posterHeight * (1.0 / 1.5) }
    private let posterHeight: CGFloat = 260

    private var columns: [GridItem] {
        return [GridItem(.adaptive(minimum: 200), spacing: 24)]
    }

    init(person: SeerrPerson) {
        self.person = person
        self.personId = person.id
        self.loadedData = true
    }

    init(personId: Int) {
        self.person = nil
        self.personId = personId
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                self.header

                self.content
            }
        }
        .background { Color.bgPurple.ignoresSafeArea() }
        .task {
            self.person = try? await self.fetchPerson()
            self.personContent = await self.fetchContent()
        }
    }

    @ViewBuilder
    private var header: some View {
        if let person {
            VStack(alignment: .leading, spacing: 15.0) {
                HStack {
                    AsyncImage(url: person.image) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: self.posterWidth, height: self.posterHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(alignment: .bottomTrailing) {
                                Image(systemName: person.gender.symbol)
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(Color.primary)
                                    .frame(width: 35, height: 35)
                                    .padding(7.0)
                                    .glassEffect(.clear.tint(person.gender.color.opacity(0.4)), in: Circle())
                                    .padding(10.0)
                            }
                    } placeholder: {
                        Image(systemName: "person.crop.artframe")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(person.gender.color)
                            .frame(width: self.posterWidth, height: self.posterHeight)
                    }

                    VStack(alignment: .leading) {
                        Text(person.name)
                            .font(.title.bold())
                            .multilineTextAlignment(.leading)
                            .lineLimit(person.age == nil ? 2 : 1)

                        if let age = person.age {
                            Text("person.age-\(age)")
                                .foregroundStyle(Color.secondary)
                                .font(.callout.width(.condensed))
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var content: some View {
        if !self.personContent.isEmpty {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(self.personContent) { item in
                    DiscoverItemRow(item: item)
                }
            }
            .padding()
        }
    }

    private func fetchPerson() async throws -> SeerrPerson {
        let (data, res, _) = try await SeerSession.shared.raw(Person.get(id: self.personId))
        let code = res?.statusCode ?? -1

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], code == 200 {
            return .init(data: json)
        }
        throw SeerrError()
    }

    private func fetchContent() async -> [DiscoverItem] {
        guard let (data, _, _) = try? await SeerSession.shared.raw(Person.content(id: self.personId)), let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }

        var final: [DiscoverItem] = []
        let cast: [[String: Any]]? = json["cast"] as? [[String: Any]]
        let crew: [[String: Any]]? = json["crew"] as? [[String: Any]]

        if cast?.isEmpty == false {
            let viewBlacklist: Bool = SeerSession.shared.user?.hasPermission(Permission.viewBlacklist) ?? false

            let fetched: [DiscoverItem] = cast!.map { .init(data: $0) }.filter { $0.requestStatus != .blacklisted || viewBlacklist }
            final.append(contentsOf: fetched)
        }

        if crew?.isEmpty == false {
            let viewBlacklist: Bool = SeerSession.shared.user?.hasPermission(Permission.viewBlacklist) ?? false

            let fetched: [DiscoverItem] = crew!.map { .init(data: $0) }.filter { $0.requestStatus != .blacklisted || viewBlacklist }
            final.append(contentsOf: fetched)
        }

        return final
    }
}

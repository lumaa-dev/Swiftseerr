// Made by Lumaa

import SwiftUI

struct SeerrPersonView: View {
    @State private var  person: SeerrPerson?
    private let personId: Int

    @State private var loadedData: Bool = false
    @State private var shortenedBio: Bool = true

    @State private var personContent: [DiscoverItem] = []

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

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

                if let person, let bio = person.bio {
                    Text(bio)
                        .font(.callout)
                        .multilineTextAlignment(.leading)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 20.0))
                        .padding(.horizontal)
                        .frame(maxHeight: shortenedBio ? 100 : .infinity)
                        .onTapGesture {
                            withAnimation(.smooth) {
                                self.shortenedBio.toggle()
                            }
                        }
                }

                self.content
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.bgPurple)
        .navigationTitle(Text(person?.name ?? String("")))
        .task {
            self.person = try? await self.fetchPerson()
            self.personContent = await self.fetchContent()
        }
    }

    @ViewBuilder
    private var header: some View {
        if let person {
            AsyncImage(url: person.image) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: person.gender.symbol)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(Color.primary)
                            .frame(width: 35, height: 35)
                            .padding(7.0)
                            .glassEffect(.clear.tint(person.gender.color.opacity(0.4)), in: Circle())
                    }
            } placeholder: {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .foregroundStyle(person.gender.color)
                    .frame(width: 150, height: 150)
            }
            .stretchy(amplify: 0.65)
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

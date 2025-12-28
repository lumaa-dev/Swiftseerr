// Made by Lumaa

import SwiftUI

struct PersonPlate: View {
    let person: MediaPerson

    init(_ person: MediaPerson) {
        self.person = person
    }

    var body: some View {
        NavigationLink {
            SeerrPersonView(personId: self.person.tmdbId)
        } label: {
            VStack(spacing: 10.0) {
                profileImage

                Text(person.name)
                    .font(.body.bold())
                    .lineLimit(1)
                    .multilineTextAlignment(.center)

                Text(person.description)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 150, height: 200)
            .padding()
            .foregroundStyle(Color.primary)
            .background(Material.ultraThin)
            .clipShape(RoundedRectangle(cornerRadius: 10.0))
        }
        .navigationLinkIndicatorVisibility(.hidden)
    }

    @ViewBuilder
    private var profileImage: some View {
        AsyncImage(url: person.personPath) { image in
            image
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
        } placeholder: {
            Image(systemName: "person.crop.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(Color.white)
        }
    }
}

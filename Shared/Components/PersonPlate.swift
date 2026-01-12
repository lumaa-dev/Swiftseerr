// Made by Lumaa

import SwiftUI

struct PersonPlate: View {
    let person: MediaPerson

    #if os(tvOS)
    private var imageWidth: CGFloat { self.imageHeight * (1.0 / 1.5) }
    private let imageHeight: CGFloat = 340
    #else
    private var imageWidth: CGFloat = 100
    private let imageHeight: CGFloat = 100
    #endif

    init(_ person: MediaPerson) {
        self.person = person
    }

    var body: some View {
        NavigationLink {
            SeerrPersonView(personId: self.person.tmdbId)
        } label: {
            #if !os(tvOS)
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
            #else
            profileImage

            Text(person.name)
                .font(.system(size: 21))
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.center)
            #endif
        }
        .navigationLinkIndicatorVisibility(.hidden)
        #if os(tvOS)
        .buttonStyle(.borderless)
        #endif
    }

    @ViewBuilder
    private var profileImage: some View {
        AsyncImage(url: person.personPath) { image in
            image
                .resizable()
                .scaledToFill()
                .frame(width: self.imageWidth, height: self.imageHeight)
                #if !os(tvOS)
                .clipShape(Circle())
                #endif
        } placeholder: {
            #if os(tvOS)
            let sf: String = "person.crop.artframe"
            #else
            let sf: String = "person.crop.circle"
            #endif
            
            Image(systemName: sf)
                .resizable()
                .scaledToFit()
                .frame(width: self.imageWidth, height: self.imageHeight)
                .foregroundStyle(Color.white)
        }
    }
}

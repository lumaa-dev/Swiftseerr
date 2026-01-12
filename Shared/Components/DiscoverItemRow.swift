// Made by Lumaa

import SwiftUI

struct DiscoverItemRow: View {
    let item: DiscoverItem

    private var width: CGFloat { self.height * (1.0 / 1.5) }
    #if !os(tvOS) && !os(macOS)
    private let height: CGFloat = 260
    #else
    private let height: CGFloat = 340
    #endif

    var body: some View {
        NavigationLink {
            MediaItemView(mediaId: item.id, type: item.type)
        } label: {
            #if !os(tvOS)
            VStack(spacing: 4) {
                self.poster

                Text(item.name)
                    #if !os(macOS)
                    .font(.system(size: 14))
                    #else
                    .font(.system(size: 21))
                    #endif
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
                    .frame(width: self.width, alignment: .leading)
            }
            .frame(width: self.width)
            #else
            self.poster

            Text(item.name)
                .font(.system(size: 21))
                .foregroundStyle(Color.primary)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.center)
                .frame(width: self.width, alignment: .center)
            #endif
        }
        #if !os(tvOS)
        .frame(width: self.width)
        .buttonStyle(.plain)
        #else
        .buttonStyle(.borderless)
        .mediaContext(item)
        #endif
    }

    @ViewBuilder
    var poster: some View {
        ZStack(alignment: .topLeading) {
            AsyncImage(url: item.image ?? URL(string: "\(SeerSession.shared.auth.address)/images/jellyseerr_poster_not_found.png")) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: self.width, height: self.height)
            } placeholder: {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: self.width, height: self.height)
                    .overlay {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
            }

            #if !os(tvOS)
            Text(item.type == .movie ? "movie" : "show")
                .textCase(.uppercase)
                .font(.caption.bold().lowercaseSmallCaps())
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .glassEffect(.clear.tint(item.type == .movie ? Color.accentBlue.opacity(0.7) : Color.showPurple.opacity(0.7)))
                .clipShape(Capsule())
                .padding(6)
            #endif
        }
        #if !os(tvOS)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .mediaContext(item)
        #endif
    }
}

// Made by Lumaa

import SwiftUI

struct DiscoverItemRow: View {
    let item: DiscoverItem

    private var width: CGFloat { self.height * (1.0 / 1.5) }
    private let height: CGFloat = 260

    var body: some View {
        NavigationLink {
            MediaItemView(mediaId: item.id, type: item.type)
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topLeading) {
                    poster
                        .frame(width: width, height: height)

                    Text(item.type == .movie ? "movie" : "show")
                        .textCase(.uppercase)
                        .font(.caption2.bold().lowercaseSmallCaps())
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .glassEffect(.clear.tint(item.type == .movie ? Color.accentBlue.opacity(0.7) : Color.showPurple.opacity(0.7)))
                        .clipShape(Capsule())
                        .padding(6)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(item.name)
                    .font(.system(size: 14))
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
                    .frame(width: self.width, alignment: .leading)
            }
            .frame(width: self.width)
        }
        .frame(width: self.width)
        .buttonStyle(.plain)
    }

    @ViewBuilder
    var poster: some View {
        AsyncImage(url: item.image ?? URL(string: "\(SeerSession.shared.auth.address)/images/jellyseerr_poster_not_found.png")) { image in
            image
                .resizable()
                .scaledToFill()
                .frame(width: self.width, height: self.height)
                .clipped()
        } placeholder: {
            Rectangle()
                .fill(Color.clear)
                .frame(width: self.width, height: self.height)
                .overlay {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
        }
    }
}

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
                        .glassEffect(.clear.tint(item.type == .movie ? Color.blue.opacity(0.7) : Color.purple.opacity(0.7)))
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
        AsyncImage(url: item.image) { image in
            image
                .resizable()
                .scaledToFill()
                .frame(width: self.width, height: self.height)
                .clipped()
        } placeholder: {
            Rectangle()
                .fill(Color.gray.gradient)
                .frame(width: self.width, height: self.height)
                .overlay {
                    Text(String("?"))
                        .font(.system(size: 176, weight: .ultraLight, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
        }
    }
}

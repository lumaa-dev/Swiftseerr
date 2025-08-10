// Made by Lumaa

import SwiftUI

struct VScrollItems: View {
    let items: [DiscoverItem]
    let title: LocalizedStringKey

    init(_ title: LocalizedStringKey, items: [DiscoverItem]) {
        self.title = title
        self.items = items
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2.bold())

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items) { i in
                        DiscoverItemRow(item: i)
                    }
                }
            }
            .scrollClipDisabled()
        }
        .padding(.horizontal)
    }
}

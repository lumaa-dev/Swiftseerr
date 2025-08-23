// Made by Lumaa

import SwiftUI

struct VScrollItems<Content : View>: View {
    let content: () -> Content
    let title: LocalizedStringKey

    init(_ title: LocalizedStringKey, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2.bold())

            ScrollView(.horizontal, showsIndicators: false) {
                self.content()
            }
            .scrollClipDisabled()
        }
        .padding(.horizontal)
    }
}

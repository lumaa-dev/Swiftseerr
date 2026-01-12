// Made by Lumaa

import SwiftUI

struct VScrollItems<Content : View>: View {
    let content: () -> Content
    let title: LocalizedStringKey

    #if !os(tvOS) && !os(macOS)
    let vspacing: CGFloat = 8.0
    #else
    let vspacing: CGFloat = 35.0
    #endif

    init(_ title: LocalizedStringKey, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: vspacing) {
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

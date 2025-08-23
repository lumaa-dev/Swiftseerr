// Made by Lumaa

import SwiftUI

struct ButtonVScrollItems<Content : View>: View {
    let title: LocalizedStringKey
    let onTap: () -> Void
    let content: () -> Content
    let asNavigation: Bool

    init(_ title: LocalizedStringKey, asNavigation: Bool = true, onTap: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.onTap = onTap
        self.content = content
        self.asNavigation = asNavigation
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            Button {
                self.onTap()
            } label: {
                if asNavigation {
                    HStack(spacing: 12.0) {
                        Text(title)
                            .foregroundStyle(Color.primary)
                            .font(.title2.bold())

                        Image(systemName: "chevron.forward")
                            .foregroundStyle(Color.secondary.opacity(0.4))
                            .font(.callout)
                    }
                } else {
                    Text(title)
                        .foregroundStyle(Color.primary)
                        .font(.title2.bold())
                }
            }
            .buttonStyle(.plain)

            ScrollView(.horizontal, showsIndicators: false) {
                self.content()
            }
            .scrollClipDisabled()
        }
        .padding(.horizontal)
    }
}

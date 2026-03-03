// Made by Lumaa

import SwiftUI

struct NavigationVScrollItems<Content : View, Destination : View>: View {
    let title: LocalizedStringKey
    let destination: () -> Destination
    let content: () -> Content

	#if !os(tvOS) && !os(macOS)
	let vspacing: CGFloat = 8.0
	#elseif os(tvOS)
	let vspacing: CGFloat = 35.0
	#else
	let vspacing: CGFloat = 12.0
	#endif

    init(_ title: LocalizedStringKey, @ViewBuilder destination: @escaping () -> Destination, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.destination = destination
        self.content = content
    }

    init(_ title: LocalizedStringKey, destination: Destination, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.destination = { destination }
        self.content = content
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: vspacing) {
            NavigationLink {
                self.destination()
            } label: {
                HStack(spacing: 12.0) {
                    Text(title)
                        .foregroundStyle(Color.primary)
						#if !os(macOS)
						.font(.title2.bold())
						#else
						.font(.title.bold())
						#endif

                    Image(systemName: "chevron.forward")
                        .foregroundStyle(Color.secondary.opacity(0.4))
                        .font(.callout)
                }
            }
            .navigationLinkIndicatorVisibility(.hidden)
            .buttonStyle(.plain)

            ScrollView(.horizontal, showsIndicators: false) {
                self.content()
            }
            .scrollClipDisabled()
        }
        .padding(.horizontal)
    }
}

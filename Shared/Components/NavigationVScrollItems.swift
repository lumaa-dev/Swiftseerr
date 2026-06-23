// Made by Lumaa

import SwiftUI

struct NavigationVScrollItems<Content : View, Destination : View>: View {
    private let title: LocalizedStringKey
    private let destination: () -> Destination
    private let content: () -> Content

	private var canScroll: Bool

	#if !os(tvOS) && !os(macOS)
	private let vspacing: CGFloat = 8.0
	#elseif os(tvOS)
	private let vspacing: CGFloat = 35.0
	#else
	private let vspacing: CGFloat = 12.0
	#endif

    init(_ title: LocalizedStringKey, @ViewBuilder destination: @escaping () -> Destination, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.destination = destination
        self.content = content
		self.canScroll = true
    }

    init(_ title: LocalizedStringKey, destination: Destination, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.destination = { destination }
        self.content = content
		self.canScroll = true
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
			.scrollDisabled(!self.canScroll)
        }
        .padding(.horizontal)
    }

	func canScroll(_ enabled: Bool = true) -> Self {
		var view: Self = self
		view.canScroll = enabled
		return view
	}
}

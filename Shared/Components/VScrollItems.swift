// Made by Lumaa

import SwiftUI

struct VScrollItems<Content : View>: View {
    private let content: () -> Content
    private let title: LocalizedStringKey

	private var canScroll: Bool

    #if !os(tvOS) && !os(macOS)
    private let vspacing: CGFloat = 8.0
    #elseif os(tvOS)
    private let vspacing: CGFloat = 35.0
	#else
	private let vspacing: CGFloat = 12.0
    #endif

    init(_ title: LocalizedStringKey, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
		self.canScroll = true
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: vspacing) {
            Text(title)
			#if !os(macOS)
                .font(.title2.bold())
			#else
				.font(.title.bold())
			#endif

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

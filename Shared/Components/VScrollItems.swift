// Made by Lumaa

import SwiftUI

struct VScrollItems<Content : View>: View {
    let content: () -> Content
    let title: LocalizedStringKey

    #if !os(tvOS) && !os(macOS)
    let vspacing: CGFloat = 8.0
    #elseif os(tvOS)
    let vspacing: CGFloat = 35.0
	#else
	let vspacing: CGFloat = 12.0
    #endif

    init(_ title: LocalizedStringKey, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
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
        }
        .padding(.horizontal)
    }
}

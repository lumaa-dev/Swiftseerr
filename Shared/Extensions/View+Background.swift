// Made by Lumaa

import SwiftUI

extension View {
    @ViewBuilder
    func fakeBackgroundExtension(rotation: Angle = .degrees(90)) -> some View {
        self
            .rotationEffect(rotation)
            .blur(radius: 7.0)
            .clipped()
    }

    @ViewBuilder
    func pill(_ tint: Color = Color.accentColor, multiply: CGFloat = 1.0) -> some View {
        self
            #if !os(tvOS)
            .padding(.vertical, 7.0 * multiply)
            .padding(.horizontal, 15.0 * multiply)
            #else
            .padding(.vertical, 12.0 * multiply)
            .padding(.horizontal, 25.0 * multiply)
            #endif
            .background(tint)
            .clipShape(Capsule())
    }

    @ViewBuilder
    func glassPill(_ tint: Color = Color.accentColor, glass: Glass = .clear, multiply: CGFloat = 1.0) -> some View {
        self
            #if !os(tvOS)
            .padding(.vertical, 7.0 * multiply)
            .padding(.horizontal, 15.0 * multiply)
            #else
            .padding(.vertical, 12.0 * multiply)
            .padding(.horizontal, 25.0 * multiply)
            #endif
            .glassEffect(glass.tint(tint.opacity(0.4)))
    }

    /// [Origin](https://nilcoalescing.com/blog/StretchyHeaderInSwiftUI/)
    @ViewBuilder
    func stretchy(amplify: Double = 1.0) -> some View {
        visualEffect { effect, geometry in
            let currentHeight = geometry.size.height
            let scrollOffset = geometry.frame(in: .scrollView).minY
            let positiveOffset = max(0, scrollOffset * amplify)

            let newHeight = currentHeight + positiveOffset
            let scaleFactor = newHeight / currentHeight

            return effect.scaleEffect(
                x: scaleFactor, y: scaleFactor,
                anchor: .bottom
            )
        }
    }
}



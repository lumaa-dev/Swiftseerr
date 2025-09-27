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
    func pill(_ tint: Color = Color.accentColor) -> some View {
        self
            .padding(.vertical, 7.0)
            .padding(.horizontal, 15.0)
            .background(tint)
            .clipShape(Capsule())
    }

    @ViewBuilder
    func glassPill(_ tint: Color = Color.accentColor, glass: Glass = .clear) -> some View {
        self
            .padding(.vertical, 7.0)
            .padding(.horizontal, 15.0)
            .glassEffect(glass.tint(tint.opacity(0.4)))
    }

    /// [Origin](https://nilcoalescing.com/blog/StretchyHeaderInSwiftUI/)
    @ViewBuilder
    func stretchy() -> some View {
        visualEffect { effect, geometry in
            let currentHeight = geometry.size.height
            let scrollOffset = geometry.frame(in: .scrollView).minY
            let positiveOffset = max(0, scrollOffset)

            let newHeight = currentHeight + positiveOffset
            let scaleFactor = newHeight / currentHeight

            return effect.scaleEffect(
                x: scaleFactor, y: scaleFactor,
                anchor: .bottom
            )
        }
    }
}



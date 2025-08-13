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
}

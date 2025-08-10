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
}

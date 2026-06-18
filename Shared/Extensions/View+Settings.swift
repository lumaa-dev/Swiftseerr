// Made by Lumaa

import SwiftUI

extension View {
    #if !os(tvOS)
    /// Can only be added inside of any `Navigation`-related SwiftUI component
    @ViewBuilder
    func addSettings() -> some View {
        self
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
					NavigationLink(value: Navigator.Paths.settings) {
                        Label("settings", systemImage: "gear")
                    }
                }
            }
    }
    #endif
}

// Made by Lumaa

import SwiftUI

extension View {
    /// Can only be added inside of any `Navigation`-related SwiftUI component
    @ViewBuilder
    func addSettings() -> some View {
        self
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("settings", systemImage: "gear")
                    }
                }
            }
    }
}

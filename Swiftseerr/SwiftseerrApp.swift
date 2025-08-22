// Made by Lumaa

import SwiftUI
import SwiftData

@main
struct SwiftseerrApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.colorScheme, ColorScheme.dark)
        }
        .modelContainer(for: AuthInfo.self, isAutosaveEnabled: true)
    }
}

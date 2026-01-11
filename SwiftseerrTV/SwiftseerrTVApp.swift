// Made by Lumaa

import SwiftUI
import SwiftData

@main
struct SwiftseerrTVApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: AuthInfo.self, isAutosaveEnabled: true)
    }
}

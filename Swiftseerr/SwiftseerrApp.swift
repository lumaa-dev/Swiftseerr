// Made by Lumaa

import SwiftUI
import SwiftData

@main
struct SwiftseerrApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 400, minHeight: 600)
                .environment(\.colorScheme, ColorScheme.dark)
        }
        .windowResizability(.contentSize)
        .modelContainer(for: AuthInfo.self, isAutosaveEnabled: true)
    }
}

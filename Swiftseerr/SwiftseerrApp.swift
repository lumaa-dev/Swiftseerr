// Made by Lumaa

import SwiftUI
import SwiftData

@main
struct SwiftseerrApp: App {
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate: AppDelegate
    #endif

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

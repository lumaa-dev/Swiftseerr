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
			#if os(macOS)
				.frame(minWidth: 1000, minHeight: 600)
			#endif
                .environment(\.colorScheme, ColorScheme.dark)
        }
        .windowResizability(.contentSize)
        .modelContainer(for: AuthInfo.self, isAutosaveEnabled: true)
    }
}

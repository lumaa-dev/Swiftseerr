// Made by Lumaa

import SwiftUI
import UIKit
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate {
    @AppStorage("notifUrl") private static var notifUrl: String?
    static var hasNotificationServer: Bool {
        return self.notifUrl != nil
    }

    static var hasNotifications: Bool = false
    static var failedToken: Bool = true
    
    /// Device token used for only for APNs
    static var deviceToken: String = ""
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Self.requestNotifications()
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        AppDelegate.deviceToken = token
        UserDefaults.standard.setValue(token, forKey: "deviceToken")
        
        print("Got deviceToken")
    }

    static func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            Task { @MainActor in
                if granted {
                    print("GRANTED NOTIF")
#if !WIDGET
                    try await UNUserNotificationCenter.current().setBadgeCount(0)
                    UIApplication.shared.registerForRemoteNotifications()
                    AppDelegate.hasNotifications = true
                    AppDelegate.failedToken = true

                    if let deviceToken = UserDefaults.standard.string(forKey: "deviceToken") {
                        AppDelegate.deviceToken = deviceToken
                    }
#endif
                } else {
                    print("DENIED NOTIF")
                    AppDelegate.hasNotifications = false
                    AppDelegate.failedToken = true
                }
            }
        }
    }
}

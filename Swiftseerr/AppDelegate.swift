// Made by Lumaa

import SwiftUI
import UserNotifications

#if canImport(UIKit)
import UIKit

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
		UNUserNotificationCenter.current().delegate = self
        Self.requestNotifications {_ in}

        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        AppDelegate.deviceToken = token
        UserDefaults.standard.setValue(token, forKey: "deviceToken")
        
        print("Got deviceToken")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        AppDelegate.failedToken = false
        print(error)
    }

    static func requestNotifications(completionHandler: (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            Task { @MainActor in
                if granted {
                    print("GRANTED NOTIF")

					do {
						try await UNUserNotificationCenter.current().setBadgeCount(0)
						UIApplication.shared.registerForRemoteNotifications()
						AppDelegate.hasNotifications = true
						AppDelegate.failedToken = true
					} catch {
						print("[AppDelegate+requestNotifications] \(error)")
					}

                    if let deviceToken = UserDefaults.standard.string(forKey: "deviceToken") {
                        AppDelegate.deviceToken = deviceToken
                    } else {
                        print("MISSING DEVICETOKEN")
                    }

                } else {
                    print("DENIED NOTIF")
                    AppDelegate.hasNotifications = false
                    AppDelegate.failedToken = true
                }
            }
        }

        completionHandler(AppDelegate.hasNotifications)
    }
}
#elseif canImport(AppKit)
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
	@AppStorage("notifUrl") private static var notifUrl: String?

	static var hasNotificationServer: Bool {
		return self.notifUrl != nil
	}

	static var hasNotifications: Bool = false
	static var failedToken: Bool = true

	/// Device token used only for APNs
	static var deviceToken: String = ""

	func applicationDidFinishLaunching(_ notification: Notification) {
		UNUserNotificationCenter.current().delegate = self
		Self.requestNotifications { _ in }
	}

	func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
		AppDelegate.deviceToken = token
		UserDefaults.standard.setValue(token, forKey: "deviceToken")

		print("Got deviceToken")
	}

	func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
		AppDelegate.failedToken = false
		print(error)
	}

	static func requestNotifications(completionHandler: (Bool) -> Void) {
		UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
			Task { @MainActor in
				if granted {
					print("GRANTED NOTIF")

					do {
						try await UNUserNotificationCenter.current().setBadgeCount(0)
						NSApplication.shared.registerForRemoteNotifications()
						AppDelegate.hasNotifications = true
						AppDelegate.failedToken = true
					} catch {
						print("[AppDelegate+requestNotifications] \(error)")
					}

					if let deviceToken = UserDefaults.standard.string(forKey: "deviceToken") {
						AppDelegate.deviceToken = deviceToken
					} else {
						print("MISSING DEVICETOKEN")
					}
				} else {
					print("DENIED NOTIF")
					AppDelegate.hasNotifications = false
					AppDelegate.failedToken = true
				}
			}
		}

		completionHandler(AppDelegate.hasNotifications)
	}
}
#endif

extension AppDelegate: UNUserNotificationCenterDelegate {
	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		let userInfo = response.notification.request.content.userInfo

		if let urlString = userInfo["destination"] as? String, let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
			UIApplication.shared.open(url)
		} else {
			UIApplication.shared.open(URL(string: "swiftseerr://")!)
		}

		completionHandler()
	}
}

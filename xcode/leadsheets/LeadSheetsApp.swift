import DeadSheetsKit
import os
import SwiftUI

#if os(iOS)
import CarPlay
#endif

@main
struct LeadSheetsApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) var appDelegate
    #endif

    init() {
        LegacyStoreCleanup.run()
        for problem in Catalog.bundled.problems {
            Logger.catalog.fault("\(problem, privacy: .public)")
        }

        #if os(iOS)
        _ = WatchConnectivityManager.shared
        #endif

        // Initialize CloudKit sync
        #if os(iOS) || os(macOS)
        _ = CloudSyncManager.shared
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

#if os(iOS)
// AppDelegate to handle CarPlay setup and remote notifications
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Register for remote notifications (required for CloudKit subscriptions)
        application.registerForRemoteNotifications()
        return true
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Forward CloudKit notifications to sync manager
        CloudSyncManager.shared.handleRemoteNotification(userInfo: userInfo)
        completionHandler(.newData)
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {

        if connectingSceneSession.role == .carTemplateApplication {
            let configuration = UISceneConfiguration(
                name: "CarPlay Configuration",
                sessionRole: connectingSceneSession.role
            )
            configuration.delegateClass = CarPlaySceneDelegate.self
            return configuration
        } else {
            let configuration = UISceneConfiguration(
                name: "Default Configuration",
                sessionRole: connectingSceneSession.role
            )
            return configuration
        }
    }
}
#endif

#if os(macOS)
import AppKit

// MacAppDelegate to handle remote notifications for CloudKit subscriptions
class MacAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register for remote notifications (required for CloudKit subscriptions)
        NSApplication.shared.registerForRemoteNotifications()
    }

    func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String: Any]) {
        // Forward CloudKit notifications to sync manager
        CloudSyncManager.shared.handleRemoteNotification(userInfo: userInfo)
    }
}
#endif


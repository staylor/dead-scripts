import DeadSheetsKit
import os
import SwiftData
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
        Task {
            await SongIndex.update()
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .defaultSize(width: 1280, height: 860)
        #endif
        #if os(iOS) || os(macOS)
        .modelContainer(UserData.container)
        #endif
        #if os(iOS) || os(macOS)
        .commands {
            SongCommands()
        }
        #endif

        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}

#if os(iOS)
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // CloudKit subscriptions deliver changes as silent pushes.
        application.registerForRemoteNotifications()
        return true
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any]
    ) async -> UIBackgroundFetchResult {
        await CloudSyncManager.shared.handleRemoteNotification(userInfo: userInfo)
        return .newData
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

final class MacAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // CloudKit subscriptions deliver changes as silent pushes.
        NSApplication.shared.registerForRemoteNotifications()
    }

    func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String: Any]) {
        Task {
            await CloudSyncManager.shared.handleRemoteNotification(userInfo: userInfo)
        }
    }
}
#endif


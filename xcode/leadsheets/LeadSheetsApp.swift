import DeadSheetsKit
import SwiftData
import SwiftUI
import os

#if os(iOS)
import CarPlay
#elseif os(macOS)
import AppKit
#endif

@main
struct LeadSheetsApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) var appDelegate
    #endif

    init() {
        for problem in Catalog.bundled.problems {
            Logger.catalog.fault("\(problem, privacy: .public)")
        }

        #if os(iOS)
        _ = WatchConnectivityManager.shared
        #endif

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
        .modelContainer(UserData.shared.container)
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
        guard connectingSceneSession.role == .carTemplateApplication else {
            return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        }
        let configuration = UISceneConfiguration(name: "CarPlay Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = CarPlaySceneDelegate.self
        return configuration
    }
}
#endif

#if os(macOS)
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

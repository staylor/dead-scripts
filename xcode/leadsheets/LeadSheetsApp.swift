import SwiftUI
import SwiftData

#if os(iOS)
import CarPlay
#endif

@main
struct LeadSheetsApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    init() {
        // Initialize Watch Connectivity early
        #if os(iOS) || os(watchOS)
        _ = WatchConnectivityManager.shared
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Song.self, Artist.self, Album.self, Singer.self, Writer.self])
    }
}

#if os(iOS)
// AppDelegate to handle CarPlay setup
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        
        if connectingSceneSession.role == .carTemplateApplication {
            // CarPlay scene configuration
            let configuration = UISceneConfiguration(
                name: "CarPlay Configuration",
                sessionRole: connectingSceneSession.role
            )
            configuration.delegateClass = CarPlaySceneDelegate.self
            return configuration
        } else {
            // Default scene configuration for iPhone/iPad
            let configuration = UISceneConfiguration(
                name: "Default Configuration",
                sessionRole: connectingSceneSession.role
            )
            return configuration
        }
    }
}
#endif


import SwiftUI
import SwiftData

#if os(iOS)
import CarPlay
#endif

// MARK: - Shared Model Container
enum SharedModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([Song.self, Artist.self, Album.self, Singer.self, Writer.self])
        let config = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        return try! ModelContainer(for: schema, configurations: [config])
    }()
}

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

        // Initialize CloudKit sync
        #if os(iOS) || os(macOS)
        _ = CloudSyncManager.shared
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(SharedModelContainer.shared)
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


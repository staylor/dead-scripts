import Foundation

/// Removes the SwiftData store that earlier versions filled with a copy of `seeds.json`.
public enum LegacyStoreCleanup {
    public static func run() {
        let fileManager = FileManager.default
        for name in ["default.store", "default.store-shm", "default.store-wal"] {
            let url = URL.applicationSupportDirectory.appending(path: name)
            if fileManager.fileExists(atPath: url.path(percentEncoded: false)) {
                try? fileManager.removeItem(at: url)
            }
        }
        UserDefaults.standard.removeObject(forKey: "lastSeedsHash")
    }
}

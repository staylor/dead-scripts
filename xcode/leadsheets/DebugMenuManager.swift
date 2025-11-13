import SwiftUI
import SwiftData

@MainActor
@Observable
class DebugMenuManager {
    let modelContext: ModelContext
    @ObservationIgnored @AppStorage("hasImportedInitialData") var hasImportedInitialData = false

    var showingDebugMenu = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    var debugStatsMessage: String {
        let manager = SongDataManager(modelContext: modelContext)
        return "Songs: \(manager.getSongCount())\nImported: \(hasImportedInitialData ? "Yes" : "No")"
    }

    func resetAllData() async {
        print("🗑️ Deleting all data and resetting import flag...")

        // Delete all data
        let manager = SongDataManager(modelContext: modelContext)
        manager.deleteAllData()

        // Reset the flag
        hasImportedInitialData = false

        await reimportData()
    }

    func reimportData() async {
        do {
            print("📥 Re-importing data from seeds.json...")

            let container = modelContext.container
            let backgroundContext = ModelContext(container)

            let importService = DataImportService()
            try await importService.importEnhancedJSON(from: "seeds", into: backgroundContext)

            try backgroundContext.save()

            print("✅ Successfully re-imported seeds")
        } catch {
            print("❌ Failed to re-import data: \(error)")
        }
    }

    func printDebugStats() {
        let manager = SongDataManager(modelContext: modelContext)
        let descriptor = FetchDescriptor<Singer>()
        let singerCount = (try? modelContext.fetchCount(descriptor)) ?? 0

        print("""

        📊 Debug Stats:
        ===============
        Songs: \(manager.getSongCount())
        Artists: \(manager.getArtistCount())
        Albums: \(manager.getAlbumCount())
        Singers: \(singerCount)
        Has Imported: \(hasImportedInitialData)
        ===============

        """)
    }
}

// MARK: - View Modifier

struct DebugMenuModifier: ViewModifier {
    @Bindable var manager: DebugMenuManager

    func body(content: Content) -> some View {
        content
            .alert("Debug Menu", isPresented: $manager.showingDebugMenu) {
                Button("Reset All Data", role: .destructive) {
                    Task {
                        await manager.resetAllData()
                    }
                }
                Button("Show Stats") {
                    manager.printDebugStats()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(manager.debugStatsMessage)
            }
            #if os(macOS)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Button("Show Stats") {
                            manager.printDebugStats()
                        }
                        Divider()
                        Button("Reset All Data", role: .destructive) {
                            Task {
                                await manager.resetAllData()
                            }
                        }
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            #endif
    }
}

extension View {
    func debugMenu(manager: DebugMenuManager) -> some View {
        modifier(DebugMenuModifier(manager: manager))
    }
}

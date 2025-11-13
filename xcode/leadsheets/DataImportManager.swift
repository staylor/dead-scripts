import SwiftUI
import SwiftData

@MainActor
@Observable
class DataImportManager {
    let modelContext: ModelContext
    @ObservationIgnored @AppStorage("hasImportedInitialData") var hasImportedInitialData = false

    var isImporting = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func performInitialImport() async {
        print("🔍 DataImportManager.performInitialImport called")

        guard !hasImportedInitialData else {
            print("⏭️ Skipping import - data already exists")
            return
        }

        print("⬇️ Starting initial data import...")
        await importInitialData()
    }

    private func importInitialData() async {
        isImporting = true
        defer { isImporting = false }

        do {
            // Check if songs already exist
            let descriptor = FetchDescriptor<Song>()
            let existingSongCount = try modelContext.fetchCount(descriptor)

            if existingSongCount > 0 {
                print("⚠️ Found \(existingSongCount) songs, skipping import")
                hasImportedInitialData = true
                return
            }

            print("📥 Importing data from seeds.json...")

            let importService = DataImportService()
            try await importService.importEnhancedJSON(from: "seeds", into: modelContext)

            hasImportedInitialData = true
            print("✅ Successfully imported seeds")
        } catch {
            print("❌ Failed to import data: \(error)")
            // Don't set hasImportedInitialData on failure so it retries
        }
    }
}

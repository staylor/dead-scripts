import SwiftUI
import SwiftData
import CryptoKit

@MainActor
@Observable
class DataImportManager {
    let modelContext: ModelContext
    @ObservationIgnored @AppStorage("lastSeedsHash") var lastSeedsHash = ""

    var isImporting = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func performInitialImport() async {
        print("🔍 DataImportManager.performInitialImport called")

        // Calculate current hash of seeds.json
        guard let currentHash = calculateSeedsHash() else {
            print("❌ Could not calculate seeds.json hash")
            return
        }

        // Check if seeds.json has changed
        if lastSeedsHash == currentHash {
            print("⏭️ Skipping import - seeds.json unchanged (hash: \(currentHash.prefix(8))...)")
            return
        }

        print("🔄 seeds.json changed - reimporting data...")
        print("   Old hash: \(lastSeedsHash.prefix(8))...")
        print("   New hash: \(currentHash.prefix(8))...")
        
        await importInitialData(newHash: currentHash)
    }

    private func importInitialData(newHash: String) async {
        isImporting = true
        defer { isImporting = false }

        do {
            // Clear existing data before reimporting
            print("🗑️ Clearing existing data...")
            try clearAllData()

            print("📥 Importing data from seeds.json...")

            let importService = DataImportService()
            try await importService.importEnhancedJSON(from: "seeds", into: modelContext)

            // Store the new hash only after successful import
            lastSeedsHash = newHash
            print("✅ Successfully imported seeds (hash: \(newHash.prefix(8))...)")
        } catch {
            print("❌ Failed to import data: \(error)")
            // Don't update lastSeedsHash on failure so it retries
        }
    }
    
    /// Calculate SHA256 hash of seeds.json file
    private func calculateSeedsHash() -> String? {
        guard let url = Bundle.main.url(forResource: "seeds", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Clear all existing data from the model context
    private func clearAllData() throws {
        // Delete all songs
        try modelContext.delete(model: Song.self)
        
        // Delete all albums
        try modelContext.delete(model: Album.self)
        
        // Delete all artists
        try modelContext.delete(model: Artist.self)
        
        // Delete all singers
        try modelContext.delete(model: Singer.self)
        
        // Delete all writers
        try modelContext.delete(model: Writer.self)
        
        try modelContext.save()
        print("✅ Cleared all existing data")
    }
}

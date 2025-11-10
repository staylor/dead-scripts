import SwiftUI
import SwiftData
import PDFKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Song.name) private var allSongs: [Song]
    @AppStorage("hasImportedInitialData") private var hasImportedInitialData = false
    
    @State private var searchText = ""
    @State private var selected: Song?
    @State private var isImporting = false
    @State private var showingDebugMenu = false
    
    var filteredSongs: [Song] {
        if searchText.isEmpty {
            return allSongs
        } else {
            return allSongs.filter { song in
                song.name.localizedCaseInsensitiveContains(searchText) ||
                song.artist?.name.localizedCaseInsensitiveContains(searchText) == true ||
                song.album?.name.localizedCaseInsensitiveContains(searchText) == true ||
                song.lyrics?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // White background for entire app
                Color.white
                    .ignoresSafeArea(.all)
                
                if isImporting {
                    // Show loading indicator during import
                    VStack {
                        ProgressView("Importing songs...")
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 10)
                    }
                } else {
                    // Search Screen (always present in the background)
                    SearchScreen(
                        searchText: $searchText,
                        songs: filteredSongs,
                        onSelect: { song in
                            selected = song
                        }
                    )
                    .opacity(selected == nil ? 1 : 0)
                    
                    // PDF Viewer Screen (slides in from right)
                    if let song = selected {
                        PDFViewerScreen(song: song, onBack: {
                            selected = nil
                        })
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .trailing)
                        ))
                        .zIndex(1)
                    }
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selected)
        // Debug gesture: Long press with 3 fingers to show debug menu
        .onLongPressGesture(minimumDuration: 2.0) {
            showingDebugMenu = true
        }
        .alert("Debug Menu", isPresented: $showingDebugMenu) {
            Button("Reset Import Flag & Delete All Data", role: .destructive) {
                resetAllData()
            }
            Button("Re-import Data (Keep Flag)", role: .destructive) {
                Task {
                    await importInitialData()
                }
            }
            Button("Show Stats") {
                printDebugStats()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Songs: \(allSongs.count)\nImported: \(hasImportedInitialData ? "Yes" : "No")")
        }
        .task {
            print("🔍 ContentView.task called")
            print("📊 Current song count: \(allSongs.count)")
            print("✅ Has imported data before: \(hasImportedInitialData)")
            
            if !hasImportedInitialData {
                print("⬇️ Starting initial data import...")
                await importInitialData()
            } else {
                print("⏭️ Skipping import - data already exists")
            }
        }
    }
    
    private func importInitialData() async {
        isImporting = true
        defer { isImporting = false }
        
        do {
            // Double-check: if we somehow have songs already, don't import
            if allSongs.count > 0 {
                print("⚠️ Songs already exist in database (\(allSongs.count) songs), skipping import")
                hasImportedInitialData = true
                return
            }
            
            // Triple-check using a direct fetch to avoid race conditions
            let descriptor = FetchDescriptor<Song>()
            let existingSongCount = try modelContext.fetchCount(descriptor)
            
            if existingSongCount > 0 {
                print("⚠️ Found \(existingSongCount) songs via direct fetch, skipping import")
                hasImportedInitialData = true
                return
            }
            
            print("📥 Importing data from songs.json...")
            
            // Create a background context for import to avoid threading issues
            let container = modelContext.container
            let backgroundContext = ModelContext(container)
            
            let importService = DataImportService()
            
            // Import from your existing songs.json file using the CURRENT format (array-based)
            try await importService.importEnhancedJSON(from: "songs", into: backgroundContext)
            
            // Save on background context
            try backgroundContext.save()
            
            hasImportedInitialData = true
            
            print("✅ Successfully imported songs")
        } catch {
            print("❌ Failed to import data: \(error)")
            // Don't set hasImportedInitialData to true on failure
            // so it will retry next time
        }
    }
    
    // MARK: - Debug Helpers
    
    private func resetAllData() {
        print("🗑️ Deleting all data and resetting import flag...")
        
        // Delete all data
        let manager = SongDataManager(modelContext: modelContext)
        manager.deleteAllData()
        
        // Reset the flag
        hasImportedInitialData = false
        
        print("✅ Reset complete. App will re-import on next launch.")
    }
    
    private func printDebugStats() {
        let manager = SongDataManager(modelContext: modelContext)
        print("""
        
        📊 Debug Stats:
        ===============
        Songs: \(manager.getSongCount())
        Artists: \(manager.getArtistCount())
        Albums: \(manager.getAlbumCount())
        Has Imported: \(hasImportedInitialData)
        ===============
        
        """)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .modelContainer(for: [Song.self, Artist.self, Album.self, Tag.self], inMemory: true)
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
    }
}

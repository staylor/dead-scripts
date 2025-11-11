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
        #if os(macOS)
        // macOS native three-column layout: Song List | PDF | Lyrics
        NavigationSplitView {
            // Column 1: Song list
            SearchScreen(
                searchText: $searchText,
                songs: filteredSongs,
                onSelect: { song in
                    selected = song
                }
            )
            .navigationSplitViewColumnWidth(min: 280, ideal: 350, max: 450)
        } content: {
            // Column 2: PDF Viewer (content column)
            if isImporting {
                VStack {
                    ProgressView("Importing songs...")
                        .controlSize(.large)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .navigationSplitViewColumnWidth(min: 500, ideal: 700, max: 1000)
            } else if let song = selected {
                PDFViewerScreen(song: song, onBack: {
                    selected = nil
                })
                .toolbar(removing: .title)
                .navigationSplitViewColumnWidth(min: 500, ideal: 700, max: 1000)
            } else {
                ContentUnavailableView(
                    "Select a Song",
                    systemImage: "music.note",
                    description: Text("Choose a song from the list to view its lead sheet")
                )
                .toolbar(removing: .title)
                .navigationSplitViewColumnWidth(min: 500, ideal: 700, max: 1000)
            }
        } detail: {
            // Column 3: Lyrics
            if let song = selected {
                LyricsInspector(song: song)
                    .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
                    .id(song.id)
            } else {
                ContentUnavailableView(
                    "Lyrics",
                    systemImage: "text.quote",
                    description: Text("Select a song to view its lyrics")
                )
                .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .background(Color.white)
        .task {
            await performInitialImport()
        }
        #else
        // iOS/iPadOS layout
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
                            #if os(iOS)
                            .background(Color(.systemBackground))
                            #else
                            .background(Color(nsColor: .windowBackgroundColor))
                            #endif
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
        .task {
            await performInitialImport()
        }
        #endif
    }
    
    private func performInitialImport() async {
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
    
    @MainActor
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
            
            let importService = DataImportService()
            
            // Import using the main context since we're already on MainActor
            try await importService.importEnhancedJSON(from: "songs", into: modelContext)
            
            hasImportedInitialData = true
            
            print("✅ Successfully imported songs")
        } catch {
            print("❌ Failed to import data: \(error)")
            // Don't set hasImportedInitialData to true on failure
            // so it will retry next time
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .modelContainer(for: [Song.self, Artist.self, Album.self, Singer.self], inMemory: true)
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
    }
}

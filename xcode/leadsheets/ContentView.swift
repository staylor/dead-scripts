import SwiftUI
import SwiftData
import PDFKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Song.name) private var allSongs: [Song]
    @AppStorage("hasImportedInitialData") private var hasImportedInitialData = false
    
    @State private var searchText = ""
    @State private var selectedPDF: Song?
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
                            selectedPDF = song
                        }
                    )
                    .opacity(selectedPDF == nil ? 1 : 0)
                    
                    // PDF Viewer Screen (slides in from right)
                    if let song = selectedPDF {
                        PDFViewerScreen(song: song, onBack: {
                            selectedPDF = nil
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
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedPDF)
        .task {
            if !hasImportedInitialData {
                await importInitialData()
            }
        }
    }
    
    private func importInitialData() async {
        isImporting = true
        defer { isImporting = false }
        
        let importService = DataImportService()
        
        do {
            // Import from your existing songs.json file
            try await importService.importLegacyJSON(from: "songs", into: modelContext)
            hasImportedInitialData = true
            print("Successfully imported \(allSongs.count) songs")
        } catch {
            print("Failed to import data: \(error)")
        }
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

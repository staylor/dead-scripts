import SwiftUI
import SwiftData
#if !os(watchOS) && !os(tvOS)
import PDFKit
#endif

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Song.name) private var allSongs: [Song]

    @State private var searchText = ""
    @State private var selected: Song?
    @State private var importManager: DataImportManager?
    
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
            .navigationSplitViewColumnWidth(min: 450, ideal: 450, max: 550)
        } content: {
            // Column 2: PDF Viewer (content column)
            if importManager?.isImporting == true {
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
        .onAppear {
            if importManager == nil {
                importManager = DataImportManager(modelContext: modelContext)
            }
        }
        .task {
            await importManager?.performInitialImport()
        }
        #else
        // iOS/iPadOS layout
        NavigationStack {
            ZStack {
                #if !os(tvOS)
                // White background for entire app
                Color.white
                    .ignoresSafeArea(.all)
                #endif

                if importManager?.isImporting == true {
                    // Show loading indicator during import
                    VStack {
                        ProgressView("Importing songs...")
                            .padding()
                            #if os(iOS)
                            .background(Color(.systemBackground))
                            #elseif os(tvOS) || os(watchOS)
                            .background(Color.white.opacity(0.1))
                            #else
                            .background(Color(nsColor: .windowBackgroundColor))
                            #endif
                            .cornerRadius(12)
                            .shadow(radius: 10)
                    }
                } else {
                    #if os(tvOS)
                    // tvOS: Conditional rendering (no opacity trick, for proper focus)
                    if let song = selected {
                        ImageViewerScreen(song: song, onBack: {
                            selected = nil
                        })
                    } else {
                        SearchScreen(
                            searchText: $searchText,
                            songs: filteredSongs,
                            onSelect: { song in
                                selected = song
                            }
                        )
                    }
                    #else
                    // iOS/iPadOS: Keep existing ZStack approach with opacity
                    SearchScreen(
                        searchText: $searchText,
                        songs: filteredSongs,
                        onSelect: { song in
                            selected = song
                        }
                    )
                    .opacity(selected == nil ? 1 : 0)

                    // Viewer Screen (slides in from right)
                    #if !os(watchOS)
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
                    #endif
                    #endif
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selected)
        .onAppear {
            if importManager == nil {
                importManager = DataImportManager(modelContext: modelContext)
            }
        }
        .task {
            await importManager?.performInitialImport()
        }
        #endif
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .modelContainer(for: [Song.self, Artist.self, Album.self, Singer.self, Writer.self], inMemory: true)
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
    }
}

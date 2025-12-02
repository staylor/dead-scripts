import SwiftUI
import SwiftData
#if !os(watchOS) && !os(tvOS)
import PDFKit
#endif

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var selected: Song?
    @State private var importManager: DataImportManager?

    #if os(iOS) || os(watchOS)
    @ObservedObject private var watchConnectivity = WatchConnectivityManager.shared
    #endif

    #if os(iOS) || os(macOS)
    @ObservedObject private var cloudSync = CloudSyncManager.shared
    #endif

    private func findSong(bySlug slug: String) -> Song? {
        let predicate = #Predicate<Song> { $0.slug == slug }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }
    
    // MARK: - Helper Methods

    #if os(macOS)
    private func subtitleText(for song: Song) -> String {
        var subtitle = ""
        if let album = song.album {
            subtitle += album.name
            if let year = album.releaseYear { subtitle += " (\(year))" }
            subtitle += " • "
        }
        subtitle += song.writersDisplayText
        let singer = song.singerDisplayText
        if !singer.isEmpty { subtitle += " • \(singer)" }
        return subtitle
    }
    #endif

    private func selectSong(_ song: Song) {
        selected = song

        #if DEBUG
        print("selectSong: \(song.name), slug: \(song.slug ?? "nil")")
        #endif

        guard let slug = song.slug else {
            #if DEBUG
            print("selectSong: no slug, skipping sync")
            #endif
            return
        }

        #if os(iOS)
        // Direct Watch sync (iPhone only)
        watchConnectivity.sendSelectedSong(songID: slug, songName: song.name)
        // CloudKit sync (for iPad → iPhone → Watch flow)
        cloudSync.sendSelection(slug: slug)
        #elseif os(macOS)
        // CloudKit sync from Mac
        cloudSync.sendSelection(slug: slug)
        #endif
    }
    
    var body: some View {
        #if os(macOS)
        // macOS native three-column layout: Song List | PDF | Lyrics
        NavigationSplitView {
            // Column 1: Song list
            FilteredSongsView(searchText: searchText) { songs in
                SearchScreen(
                    searchText: $searchText,
                    songs: songs,
                    onSelect: { song in
                        selectSong(song)
                    }
                )
            }
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
                .navigationSplitViewColumnWidth(min: 500, ideal: 700, max: .infinity)
            } else if let song = selected {
                PDFViewerScreen(song: song, onBack: {
                    selected = nil
                })
                .navigationTitle(song.name)
                .navigationSubtitle(subtitleText(for: song))
                .navigationSplitViewColumnWidth(min: 500, ideal: 700, max: .infinity)
            } else {
                ContentUnavailableView(
                    "Select a Song",
                    systemImage: "music.note",
                    description: Text("Choose a song from the list to view its lead sheet")
                )
                .toolbar(removing: .title)
                .navigationSplitViewColumnWidth(min: 500, ideal: 700, max: .infinity)
            }
        } detail: {
            // Column 3: Lyrics
            if let song = selected {
                LyricsInspector(songID: song.persistentModelID)
                    .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
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
        .modifier(ImportManagerModifier(
            modelContext: modelContext,
            importManager: $importManager
        ))
        .onChange(of: cloudSync.selectedSongSlug) { _, newValue in
            guard let slug = newValue,
                  selected?.slug != slug,
                  let matchingSong = findSong(bySlug: slug) else { return }
            selected = matchingSong
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
                        FilteredSongsView(searchText: searchText) { songs in
                            SearchScreen(
                                searchText: $searchText,
                                songs: songs,
                                onSelect: { song in
                                    selected = song
                                }
                            )
                        }
                    }
                    #else
                    // iOS/iPadOS: Keep existing ZStack approach with opacity
                    FilteredSongsView(searchText: searchText) { songs in
                        SearchScreen(
                            searchText: $searchText,
                            songs: songs,
                            onSelect: { song in
                                selectSong(song)
                            }
                        )
                    }
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
        .modifier(ImportManagerModifier(
            modelContext: modelContext,
            importManager: $importManager
        ))
        #if os(iOS)
        // Listen for song selections from Watch (iPhone only) and forward to CloudKit
        .onChange(of: watchConnectivity.selectedSongID) { _, newValue in
            guard UIDevice.current.userInterfaceIdiom == .phone,
                  let slug = newValue,
                  selected?.slug != slug,
                  let matchingSong = findSong(bySlug: slug) else { return }
            selected = matchingSong
            // Forward Watch selection to CloudKit so iPad can see it
            cloudSync.sendSelection(slug: slug)
        }
        // Listen for song selections from CloudKit (from other devices)
        .onChange(of: cloudSync.selectedSongSlug) { _, newValue in
            guard let slug = newValue,
                  selected?.slug != slug,
                  let matchingSong = findSong(bySlug: slug) else { return }
            selected = matchingSong
        }
        #endif
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

import DeadSheetsKit
import SwiftUI

struct ContentView: View {
    @Environment(\.catalog) private var catalog

    @State private var searchText = ""
    @State private var selected: Song?
    #if os(macOS)
    @State private var showSettings = false

    private enum MacColumnWidth {
        static let sidebar = (min: 320.0, ideal: 380.0, max: 480.0)
        static let score = (min: 520.0, ideal: 900.0)
        static let lyrics = (min: 240.0, ideal: 320.0, max: 420.0)
    }
    #endif

    #if os(iOS)
    private let watchConnectivity = WatchConnectivityManager.shared
    #endif

    #if os(iOS) || os(macOS)
    private let cloudSync = CloudSyncManager.shared
    #endif

    #if os(macOS)
    private func subtitleText(for song: Song) -> String {
        var subtitle = song.albumTitle
        if let year = song.albumReleaseYear {
            subtitle += " (\(year))"
        }
        subtitle += " • \(song.creditsText)"
        if let singer = song.singer {
            subtitle += " • Original singer: \(singer.name)"
        }
        return subtitle
    }
    #endif

    private func selectSong(_ song: Song) {
        selected = song
        #if os(iOS)
        watchConnectivity.sendSelectedSong(id: song.id)
        cloudSync.sendSelection(slug: song.id)
        #elseif os(macOS)
        cloudSync.sendSelection(slug: song.id)
        #endif
    }

    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            SearchScreen(searchText: $searchText, onSelect: selectSong, selectedSong: selected)
                .navigationSplitViewColumnWidth(min: MacColumnWidth.sidebar.min, ideal: MacColumnWidth.sidebar.ideal, max: MacColumnWidth.sidebar.max)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape")
                        }
                        .popover(isPresented: $showSettings) {
                            SettingsView()
                        }
                    }
                }
        } content: {
            if let song = selected {
                PDFViewerScreen(song: song, onBack: {
                    selected = nil
                })
                .navigationTitle(song.title)
                .navigationSubtitle(subtitleText(for: song))
                .navigationSplitViewColumnWidth(min: MacColumnWidth.score.min, ideal: MacColumnWidth.score.ideal, max: .infinity)
            } else {
                ContentUnavailableView(
                    "Select a Song",
                    systemImage: "music.note",
                    description: Text("Choose a song from the list to view its lead sheet")
                )
                .toolbar(removing: .title)
                .navigationSplitViewColumnWidth(min: MacColumnWidth.score.min, ideal: MacColumnWidth.score.ideal, max: .infinity)
            }
        } detail: {
            if let song = selected {
                LyricsInspector(song: song)
                    .navigationSplitViewColumnWidth(min: MacColumnWidth.lyrics.min, ideal: MacColumnWidth.lyrics.ideal, max: MacColumnWidth.lyrics.max)
            } else {
                ContentUnavailableView(
                    "Lyrics",
                    systemImage: "text.quote",
                    description: Text("Select a song to view its lyrics")
                )
                .navigationSplitViewColumnWidth(min: MacColumnWidth.lyrics.min, ideal: MacColumnWidth.lyrics.ideal, max: MacColumnWidth.lyrics.max)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .playbackAlerts()
        .onChange(of: cloudSync.selectedSongSlug) { _, newValue in
            guard let slug = newValue, selected?.id != slug, let song = catalog.song(id: slug) else { return }
            selected = song
        }
        #else
        NavigationStack {
            ZStack {
                #if os(tvOS)
                // Conditional rather than layered views, so focus moves to the visible screen.
                if let song = selected {
                    ImageViewerScreen(song: song, onBack: {
                        selected = nil
                    })
                } else {
                    SearchScreen(searchText: $searchText, onSelect: { selected = $0 })
                }
                #else
                if selected == nil {
                    SearchScreen(searchText: $searchText, onSelect: selectSong)
                        .transition(.opacity)
                }

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
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selected)
        #if os(iOS)
        .playbackAlerts()
        .onChange(of: watchConnectivity.selectedSongID) { _, newValue in
            guard UIDevice.current.userInterfaceIdiom == .phone,
                  let slug = newValue,
                  selected?.id != slug,
                  let song = catalog.song(id: slug) else { return }
            selected = song
            // Forward the watch's selection so an iPad following along sees it too.
            cloudSync.sendSelection(slug: slug)
        }
        .onChange(of: cloudSync.selectedSongSlug) { _, newValue in
            guard let slug = newValue, selected?.id != slug, let song = catalog.song(id: slug) else { return }
            selected = song
        }
        #endif
        #endif
    }
}

#Preview {
    ContentView()
}

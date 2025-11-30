import SwiftUI
import SwiftData
import WatchConnectivity
import WatchKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Song.name) private var songs: [Song]
    @ObservedObject private var connectivityManager = WatchConnectivityManager.shared

    @State private var navigationPath = NavigationPath()
    @State private var importManager: DataImportManager?

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List(songs) { song in
                NavigationLink(value: song) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(song.name)
                            .font(.headline)

                        if let artist = song.artist {
                            Text(artist.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let album = song.album {
                            Text(album.name)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .navigationTitle("Songs")
            .navigationDestination(for: Song.self) { song in
                LyricsDetailView(song: song)
                    .onAppear {
                        // Send selection to iPhone
                        connectivityManager.sendSelectedSong(songID: song.slug ?? "", songName: song.name)
                    }
            }
            .onAppear {
                if importManager == nil {
                    importManager = DataImportManager(modelContext: modelContext)
                }
                // Check for any pending song selection from application context
                let context = WCSession.default.receivedApplicationContext
                if let songID = context["selectedSongID"] as? String {
                    connectivityManager.selectedSongID = songID
                }
            }
            .task {
                await importManager?.performInitialImport()
            }
            .onChange(of: connectivityManager.selectedSongID) { _, newID in
                // Navigate to the selected song when received from iPhone (match by slug)
                if let newID = newID,
                   let song = songs.first(where: { $0.slug == newID }) {
                    WKInterfaceDevice.current().play(.notification)
                    navigationPath.removeLast(navigationPath.count) // Pop to root
                    navigationPath.append(song)
                }
            }
        }
    }
}

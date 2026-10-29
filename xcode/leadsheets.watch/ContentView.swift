import DeadSheetsKit
import SwiftUI
import WatchKit

struct ContentView: View {
    private let catalog = Catalog.bundled
    private let connectivity = WatchConnectivityManager.shared

    @State private var path: [Song] = []
    @State private var songOpenedFromPhone: Song.ID?

    var body: some View {
        NavigationStack(path: $path) {
            List(catalog.songs) { song in
                NavigationLink(value: song) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(song.title)
                            .font(.headline)

                        Text(song.artistName)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(song.albumTitle)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .navigationTitle("Songs")
            .navigationDestination(for: Song.self) { song in
                LyricsDetailView(song: song)
                    .onAppear {
                        if songOpenedFromPhone != song.id {
                            connectivity.sendSelectedSong(id: song.id)
                        }
                        songOpenedFromPhone = nil
                    }
            }
            .onChange(of: connectivity.selection, initial: true) { _, selection in
                guard let songID = selection?.songID, path.last?.id != songID, let song = catalog.song(id: songID) else { return }
                songOpenedFromPhone = songID
                WKInterfaceDevice.current().play(.notification)
                path = [song]
            }
        }
    }
}

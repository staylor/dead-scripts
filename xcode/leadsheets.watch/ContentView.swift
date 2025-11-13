import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Song.name) private var songs: [Song]

    @State private var importManager: DataImportManager?

    var body: some View {
        NavigationStack {
            List(songs) { song in
                NavigationLink(destination: LyricsDetailView(song: song)) {
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
            .onAppear {
                if importManager == nil {
                    importManager = DataImportManager(modelContext: modelContext)
                }
            }
            .task {
                await importManager?.performInitialImport()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Song.self, Artist.self, Album.self, Singer.self])
}

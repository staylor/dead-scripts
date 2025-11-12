import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Song.name) private var songs: [Song]
    @AppStorage("hasImportedInitialData") private var hasImportedInitialData = false

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
            .task {
                await performInitialImport()
            }
        }
    }

    private func performInitialImport() async {
        guard !hasImportedInitialData else { return }

        do {
            let descriptor = FetchDescriptor<Song>()
            let existingSongCount = try modelContext.fetchCount(descriptor)

            if existingSongCount == 0 {
                let importService = DataImportService()
                try await importService.importEnhancedJSON(from: "songs", into: modelContext)
                hasImportedInitialData = true
            }
        } catch {
            print("Failed to import data: \(error)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Song.self, Artist.self, Album.self, Singer.self])
}

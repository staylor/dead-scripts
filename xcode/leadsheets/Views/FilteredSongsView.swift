import SwiftUI
import SwiftData

/// A helper view that builds the @Query predicate at init time for efficient database-level filtering
struct FilteredSongsView<Content: View>: View {
    @Query private var songs: [Song]
    let content: ([Song]) -> Content

    init(searchText: String, @ViewBuilder content: @escaping ([Song]) -> Content) {
        self.content = content

        if searchText.isEmpty {
            _songs = Query(sort: \Song.name)
        } else {
            let predicate = #Predicate<Song> { song in
                song.name.localizedStandardContains(searchText) ||
                (song.artist?.name.localizedStandardContains(searchText) ?? false) ||
                (song.album?.name.localizedStandardContains(searchText) ?? false) ||
                (song.lyrics?.localizedStandardContains(searchText) ?? false)
            }
            _songs = Query(filter: predicate, sort: \Song.name)
        }
    }

    var body: some View {
        content(songs)
    }
}

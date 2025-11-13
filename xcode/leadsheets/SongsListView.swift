import SwiftUI

struct SongsListView: View {
    let songs: [Song]
    let onSelect: (Song) -> Void

    var body: some View {
        PlatformListView(
            items: songs,
            emptyContent: {
                EmptyStateView(filter: .allSongs)
            },
            rowContent: { song in
                SongRowView(song: song)
            },
            onSelect: onSelect
        )
    }
}

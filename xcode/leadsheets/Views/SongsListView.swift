import SwiftUI

struct SongsListView: View {
    let songs: [Song]
    let onSelect: (Song) -> Void
    var selectedSong: Song? = nil

    var body: some View {
        PlatformListView(
            items: songs,
            emptyContent: {
                EmptyStateView(filter: .allSongs)
            },
            rowContent: { song in
                SongRowView(song: song, isSelected: selectedSong?.id == song.id)
            },
            onSelect: onSelect
        )
    }
}

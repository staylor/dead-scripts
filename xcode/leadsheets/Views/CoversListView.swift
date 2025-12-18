import SwiftUI

struct CoversListView: View {
    let songs: [Song]
    let onSelect: (Song) -> Void
    var selectedSong: Song? = nil

    var body: some View {
        PlatformListView(
            items: songs,
            emptyContent: {
                EmptyStateView(filter: .covers)
            },
            rowContent: { song in
                SongRowView(song: song, isSelected: selectedSong?.id == song.id)
            },
            onSelect: onSelect
        )
    }
}

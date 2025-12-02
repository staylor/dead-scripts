import SwiftUI

struct CoversListView: View {
    let songs: [Song]
    let onSelect: (Song) -> Void

    var body: some View {
        PlatformListView(
            items: songs,
            emptyContent: {
                EmptyStateView(filter: .covers)
            },
            rowContent: { song in
                SongRowView(song: song)
            },
            onSelect: onSelect
        )
    }
}

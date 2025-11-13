import SwiftUI

struct AlbumsListView: View {
    let albums: [Album]
    let onSelectAlbum: (Album) -> Void

    var body: some View {
        PlatformListView(
            items: albums,
            emptyContent: {
                EmptyStateView(filter: .byAlbum)
            },
            rowContent: { album in
                AlbumRowView(album: album)
            },
            onSelect: onSelectAlbum
        )
    }
}

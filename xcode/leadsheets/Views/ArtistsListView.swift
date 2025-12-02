import SwiftUI

struct ArtistsListView: View {
    let artists: [Artist]
    let onSelectArtist: (Artist) -> Void

    var body: some View {
        PlatformListView(
            items: artists,
            emptyContent: {
                EmptyStateView(filter: .byArtist)
            },
            rowContent: { artist in
                ArtistRowView(artist: artist)
            },
            onSelect: onSelectArtist
        )
    }
}

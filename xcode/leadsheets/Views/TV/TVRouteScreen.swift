#if os(tvOS)
import DeadSheetsKit
import SwiftUI

/// An album, artist, singer or writers: the artwork and details beside the songs.
struct TVRouteScreen: View {
    let route: LibraryRoute

    @Environment(\.catalog) private var catalog

    var body: some View {
        HStack(alignment: .top, spacing: 80) {
            VStack(alignment: .leading, spacing: 32) {
                TVArtwork(appleMusicID: route.appleMusicID, placeholder: route.placeholder)
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(route.isPortrait ? AnyShape(.circle) : AnyShape(.rect(cornerRadius: 24)))
                    .shadow(color: .black.opacity(0.4), radius: 24, y: 12)
                VStack(alignment: .leading, spacing: 8) {
                    Text(route.title)
                        .font(.title2)
                        .bold()
                    Text(route.summary(in: catalog))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 480)
            SongList(songs: route.songs(in: catalog), selection: .constant(nil))
        }
    }
}
#endif

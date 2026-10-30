import DeadSheetsKit
import SwiftUI

struct SongRow: View {
    let song: Song

    var body: some View {
        LibraryRow(id: "song-\(song.id)", title: song.title, subtitle: song.artistAndAlbum) {
            ArtworkThumbnail(appleMusicID: song.albumAppleMusicID, placeholder: "music.note")
        }
    }

}

/// An album, artist, singer or writers.
struct RouteRow: View {
    let route: LibraryRoute

    @Environment(\.catalog) private var catalog

    var body: some View {
        LibraryRow(id: route.id, title: route.title, subtitle: route.summary(in: catalog)) {
            ArtworkThumbnail(appleMusicID: route.appleMusicID, placeholder: route.placeholder, isPortrait: route.isPortrait)
        }
    }
}

private struct LibraryRow<Thumbnail: View>: View {
    let id: String
    let title: String
    let subtitle: String
    @ViewBuilder let thumbnail: Thumbnail

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let wraps = dynamicTypeSize.isAccessibilitySize
        HStack(spacing: 12) {
            thumbnail
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .lineLimit(wraps ? nil : 2)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(wraps ? nil : 1)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(id)
    }
}

enum Counts {
    static func songs(_ count: Int) -> String {
        String(AttributedString(localized: "^[\(count) song](inflect: true)").characters)
    }

    static func albums(_ count: Int) -> String {
        String(AttributedString(localized: "^[\(count) album](inflect: true)").characters)
    }
}

#Preview {
    let catalog = Catalog.bundled
    List {
        if let song = catalog.songs.first {
            SongRow(song: song)
        }
        if let album = catalog.albums.first {
            RouteRow(route: .album(album))
        }
        if let artist = catalog.artists.first {
            RouteRow(route: .artist(artist))
        }
        if let singer = catalog.singers.first {
            RouteRow(route: .singer(singer))
        }
        if let group = catalog.writerGroups().first {
            RouteRow(route: .writers(group))
        }
    }
}

import DeadSheetsKit
import SwiftUI

struct SongRow: View {
    let song: Song

    @Environment(\.catalog) private var catalog

    var body: some View {
        LibraryRow(id: "song-\(song.id)", title: song.title, subtitle: subtitle) {
            Artwork(fileName: song.coverFileName, placeholder: "music.note")
        }
    }

    private var subtitle: String {
        song.artistID == catalog.mainArtist?.id ? song.albumTitle : "\(song.artistName) · \(song.albumTitle)"
    }
}

struct AlbumRow: View {
    let album: Album

    @Environment(\.catalog) private var catalog

    var body: some View {
        LibraryRow(id: "album-\(album.id)", title: album.title, subtitle: subtitle) {
            Artwork(fileName: album.coverFileName, placeholder: "square.stack")
        }
    }

    private var subtitle: String {
        var parts: [String] = []
        if album.artistID != catalog.mainArtist?.id {
            parts.append(album.artistName)
        }
        if let year = album.releaseYear {
            parts.append(String(year))
        }
        parts.append(Counts.songs(album.songIDs.count))
        return parts.joined(separator: " · ")
    }
}

struct ArtistRow: View {
    let artist: Artist

    var body: some View {
        LibraryRow(
            id: "artist-\(artist.id)",
            title: artist.name,
            subtitle: "\(Counts.songs(artist.songIDs.count)) · \(Counts.albums(artist.albumIDs.count))"
        ) {
            Artwork(fileName: artist.imageFileName, placeholder: "music.mic", style: .portrait)
        }
    }
}

struct SingerRow: View {
    let singer: Person

    @Environment(\.catalog) private var catalog

    var body: some View {
        LibraryRow(id: "singer-\(singer.id)", title: singer.name, subtitle: Counts.songs(catalog.songs(sungBy: singer).count)) {
            Artwork(fileName: singer.imageFileName, placeholder: "person.wave.2", style: .portrait)
        }
    }
}

struct WriterGroupRow: View {
    let group: WriterGroup

    var body: some View {
        LibraryRow(id: "writers-\(group.id)", title: group.name, subtitle: "\(group.rolesText) · \(Counts.songs(group.songs.count))") {
            Artwork(
                fileName: group.imageFileName,
                placeholder: group.people.count > 1 ? "person.2" : "pencil.line",
                style: .portrait
            )
        }
    }
}

private struct LibraryRow<Thumbnail: View>: View {
    let id: String
    let title: String
    let subtitle: String
    @ViewBuilder let thumbnail: Thumbnail

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .lineLimit(2)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
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

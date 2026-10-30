import DeadSheetsKit
import Foundation

/// A level below a category: the songs on an album, by an artist, and so on.
enum LibraryRoute: Hashable, Identifiable {
    case album(Album)
    case artist(Artist)
    case singer(Person)
    case writers(WriterGroup)
    /// A `Setlist`, by its ID. Apple TV has no setlists.
    case setlist(UUID)

    /// Also the accessibility identifier of the route's row.
    var id: String {
        switch self {
        case .album(let album): "album-\(album.id)"
        case .artist(let artist): "artist-\(artist.id)"
        case .singer(let person): "singer-\(person.id)"
        case .writers(let group): "writers-\(group.id)"
        case .setlist(let setlistID): "setlist-\(setlistID)"
        }
    }

    var title: String {
        switch self {
        case .album(let album): album.title
        case .artist(let artist): artist.name
        case .singer(let person): person.name
        case .writers(let group): group.name
        case .setlist: ""
        }
    }

    func summary(in catalog: Catalog) -> String {
        switch self {
        case .album(let album):
            var parts = [album.artistName]
            if let year = album.releaseYear {
                parts.append(String(year))
            }
            parts.append(Counts.songs(album.songIDs.count))
            return parts.joined(separator: " · ")
        case .artist(let artist):
            return "\(Counts.songs(artist.songIDs.count)) · \(Counts.albums(artist.albumIDs.count))"
        case .singer(let person):
            return Counts.songs(catalog.songs(sungBy: person).count)
        case .writers(let group):
            return "\(group.rolesText) · \(Counts.songs(group.songs.count))"
        case .setlist:
            return ""
        }
    }

    var appleMusicID: String? {
        switch self {
        case .album(let album): album.appleMusicID
        case .artist(let artist): artist.appleMusicID
        case .singer(let person): person.appleMusicID
        case .writers(let group): group.appleMusicID
        case .setlist: nil
        }
    }

    /// The symbol shown when there's no artwork.
    var placeholder: String {
        switch self {
        case .album: "square.stack"
        case .artist: "music.mic"
        case .singer: "person.wave.2"
        case .writers(let group): group.people.count > 1 ? "person.2" : "pencil.line"
        case .setlist: "list.number"
        }
    }

    /// Artists, singers and writers have round photos, and albums square covers.
    var isPortrait: Bool {
        switch self {
        case .album, .setlist: false
        case .artist, .singer, .writers: true
        }
    }

    func songs(in catalog: Catalog) -> [Song] {
        switch self {
        case .album(let album): catalog.songs(on: album)
        case .artist(let artist): catalog.songs(by: artist)
        case .singer(let person): catalog.songs(sungBy: person)
        case .writers(let group): group.songs
        case .setlist: []
        }
    }
}

import DeadSheetsKit
import SwiftUI

enum LibraryCategory: String, CaseIterable, Identifiable, Hashable {
    case songs
    case albums
    case artists
    case singers
    case writers
    case covers

    var id: Self { self }

    var title: String {
        switch self {
        case .songs: "Songs"
        case .albums: "Albums"
        case .artists: "Artists"
        case .singers: "Singers"
        case .writers: "Writers"
        case .covers: "Covers"
        }
    }

    var systemImage: String {
        switch self {
        case .songs: "music.note.list"
        case .albums: "square.stack"
        case .artists: "music.mic"
        case .singers: "person.wave.2"
        case .writers: "pencil.line"
        case .covers: "music.quarternote.3"
        }
    }
}

/// A level below a category: the songs on an album, by an artist, and so on.
enum LibraryRoute: Hashable {
    case album(Album)
    case artist(Artist)
    case singer(Person)
    case writers(WriterGroup)

    var title: String {
        switch self {
        case .album(let album): album.title
        case .artist(let artist): artist.name
        case .singer(let person): person.name
        case .writers(let group): group.name
        }
    }

    func songs(in catalog: Catalog) -> [Song] {
        switch self {
        case .album(let album): catalog.songs(on: album)
        case .artist(let artist): catalog.songs(by: artist)
        case .singer(let person): catalog.songs(sungBy: person)
        case .writers(let group): group.songs
        }
    }
}

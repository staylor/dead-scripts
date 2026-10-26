import DeadSheetsKit
import SwiftUI

enum LibraryCategory: String, CaseIterable, Identifiable, Hashable {
    case songs
    case albums
    case artists
    case singers
    case writers
    case covers
    case setlists

    var id: Self { self }

    /// Covers are a filter on Songs where there's a Setlists category; tvOS has no setlists.
    static var browsable: [LibraryCategory] {
        #if os(tvOS)
        [.songs, .albums, .artists, .singers, .writers, .covers]
        #else
        [.songs, .albums, .artists, .singers, .writers, .setlists]
        #endif
    }

    var title: String {
        switch self {
        case .songs: "Songs"
        case .albums: "Albums"
        case .artists: "Artists"
        case .singers: "Singers"
        case .writers: "Writers"
        case .covers: "Covers"
        case .setlists: "Setlists"
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
        case .setlists: "list.number"
        }
    }
}

enum SongFilter: String, CaseIterable, Identifiable {
    case all
    case favorites
    case covers

    var id: Self { self }

    var title: String {
        switch self {
        case .all: "Songs"
        case .favorites: "Favorites"
        case .covers: "Covers"
        }
    }

    var systemImage: String {
        switch self {
        case .all: "music.note.list"
        case .favorites: "heart"
        case .covers: LibraryCategory.covers.systemImage
        }
    }
}

/// A level below a category: the songs on an album, by an artist, and so on.
enum LibraryRoute: Hashable {
    case album(Album)
    case artist(Artist)
    case singer(Person)
    case writers(WriterGroup)
    #if os(iOS) || os(macOS)
    case setlist(Setlist.ID)
    #endif

    var title: String {
        switch self {
        case .album(let album): album.title
        case .artist(let artist): artist.name
        case .singer(let person): person.name
        case .writers(let group): group.name
        #if os(iOS) || os(macOS)
        case .setlist: ""
        #endif
        }
    }

    func songs(in catalog: Catalog) -> [Song] {
        switch self {
        case .album(let album): catalog.songs(on: album)
        case .artist(let artist): catalog.songs(by: artist)
        case .singer(let person): catalog.songs(sungBy: person)
        case .writers(let group): group.songs
        #if os(iOS) || os(macOS)
        case .setlist: []
        #endif
        }
    }
}

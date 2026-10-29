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

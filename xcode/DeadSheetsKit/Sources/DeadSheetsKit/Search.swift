import Foundation

extension Catalog {
    /// Songs whose title, artist, album or lyrics contain `query`.
    public func songs(matching query: String) -> [Song] {
        guard !query.isEmpty else { return songs }
        return songs.filter { song in
            song.title.localizedStandardContains(query)
                || song.artistName.localizedStandardContains(query)
                || song.albumTitle.localizedStandardContains(query)
                || song.lyrics.localizedStandardContains(query)
        }
    }

    /// Covers whose title, artist or singer contain `query`.
    public func covers(matching query: String) -> [Song] {
        songs.filter { song in
            song.isCover && (
                query.isEmpty
                    || song.title.localizedStandardContains(query)
                    || song.artistName.localizedStandardContains(query)
                    || song.singer?.name.localizedStandardContains(query) == true
            )
        }
    }

    public func albums(matching query: String) -> [Album] {
        guard !query.isEmpty else { return albums }
        return albums.filter {
            $0.title.localizedStandardContains(query) || $0.artistName.localizedStandardContains(query)
        }
    }

    public func artists(matching query: String) -> [Artist] {
        guard !query.isEmpty else { return artists }
        return artists.filter { $0.name.localizedStandardContains(query) }
    }

    public func singers(matching query: String) -> [Person] {
        guard !query.isEmpty else { return singers }
        return singers.filter { $0.name.localizedStandardContains(query) }
    }
}

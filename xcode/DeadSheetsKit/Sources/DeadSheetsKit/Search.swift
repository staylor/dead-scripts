import Foundation

struct CatalogSearchQuery {
    let terms: [String]

    init(_ query: String) {
        terms = query.split(whereSeparator: \.isWhitespace).map(String.init)
    }

    func matches(_ fields: [String]) -> Bool {
        terms.allSatisfy { term in
            fields.contains { $0.localizedStandardContains(term) }
        }
    }
}

extension Catalog {
    /// Each search term can match the title, artist, album or lyrics.
    public func songs(matching query: String) -> [Song] {
        let query = CatalogSearchQuery(query)
        guard !query.terms.isEmpty else { return songs }
        return songs.filter {
            query.matches([$0.title, $0.artistName, $0.albumTitle, $0.lyrics])
        }
    }

    /// Covers also match their singer.
    public func covers(matching query: String) -> [Song] {
        let query = CatalogSearchQuery(query)
        return songs.filter {
            $0.isCover && query.matches([$0.title, $0.artistName, $0.albumTitle, $0.lyrics, $0.singer?.name ?? ""])
        }
    }

    public func albums(matching query: String) -> [Album] {
        let query = CatalogSearchQuery(query)
        guard !query.terms.isEmpty else { return albums }
        return albums.filter { query.matches([$0.title, $0.artistName]) }
    }

    public func artists(matching query: String) -> [Artist] {
        let query = CatalogSearchQuery(query)
        guard !query.terms.isEmpty else { return artists }
        return artists.filter { query.matches([$0.name]) }
    }

    public func singers(matching query: String) -> [Person] {
        let query = CatalogSearchQuery(query)
        guard !query.terms.isEmpty else { return singers }
        return singers.filter { query.matches([$0.name]) }
    }
}

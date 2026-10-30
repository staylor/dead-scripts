import Foundation

struct CatalogSearchQuery {
    let terms: [String]
    let phrase: String

    init(_ query: String) {
        terms = query.split(whereSeparator: \.isWhitespace).map(String.init)
        phrase = terms.joined(separator: " ")
    }

    var isEmpty: Bool {
        terms.isEmpty
    }

    func matches(_ fields: [String]) -> Bool {
        terms.allSatisfy { term in
            fields.contains { $0.localizedStandardContains(term) }
        }
    }

    /// Words that are all in the metadata rank first, then the whole query as a phrase, such as a lyric line, then words
    /// found anywhere. Common lyric words would otherwise bury an artist's recording among their other songs.
    func ranked<Item>(_ items: [Item], metadata: (Item) -> [String], text: (Item) -> [String]) -> [Item] {
        var tiers: [[Item]] = [[], [], []]
        for item in items {
            let metadata = metadata(item)
            let fields = metadata + text(item)
            guard matches(fields) else { continue }
            if matches(metadata) {
                tiers[0].append(item)
            } else if terms.count == 1 || fields.contains(where: { $0.localizedStandardContains(phrase) }) {
                tiers[1].append(item)
            } else {
                tiers[2].append(item)
            }
        }
        return tiers.flatMap { $0 }
    }
}

extension Catalog {
    /// Recordings whose title, artist and album contain every search word come first, in title order.
    public func songs(matching query: String) -> [Song] {
        let query = CatalogSearchQuery(query)
        guard !query.isEmpty else { return songs }
        return query.ranked(songs, metadata: { [$0.title, $0.artistName, $0.albumTitle] }, text: { [$0.lyrics] })
    }

    /// Ranked like `songs(matching:)`, with the singer as metadata.
    public func covers(matching query: String) -> [Song] {
        let covers = songs.filter(\.isCover)
        let query = CatalogSearchQuery(query)
        guard !query.isEmpty else { return covers }
        return query.ranked(
            covers, metadata: { [$0.title, $0.artistName, $0.albumTitle, $0.singer?.name ?? ""] }, text: { [$0.lyrics] })
    }

    public func albums(matching query: String) -> [Album] {
        let query = CatalogSearchQuery(query)
        guard !query.isEmpty else { return albums }
        return albums.filter { query.matches([$0.title, $0.artistName]) }
    }

    public func artists(matching query: String) -> [Artist] {
        let query = CatalogSearchQuery(query)
        guard !query.isEmpty else { return artists }
        return artists.filter { query.matches([$0.name]) }
    }

    public func singers(matching query: String) -> [Person] {
        let query = CatalogSearchQuery(query)
        guard !query.isEmpty else { return singers }
        return singers.filter { query.matches([$0.name]) }
    }
}

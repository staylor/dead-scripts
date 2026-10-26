import Foundation

/// The bundled, read-only library of songs, albums, artists and people.
public struct Catalog: Sendable {
    /// Sorted by title.
    public let songs: [Song]
    /// Sorted by title.
    public let albums: [Album]
    /// Sorted by name.
    public let artists: [Artist]
    /// People who sang at least one song, sorted by name.
    public let singers: [Person]
    /// Data errors found while building the catalog, such as references to unknown people.
    /// The app still loads; tests require this to be empty for the bundled seeds.
    public let problems: [String]

    private let songsByID: [Song.ID: Song]
    private let albumsByID: [Album.ID: Album]
    private let artistsByID: [Artist.ID: Artist]
    private let songIDsBySinger: [Person.ID: [Song.ID]]
    private let songIDsByPerson: [Person.ID: [Song.ID]]

    public static let empty = Catalog(problems: [])

    public init(seedData: Data) throws {
        let seed = try JSONDecoder().decode(SeedFile.self, from: seedData)
        self.init(seed: seed)
    }

    init(problems: [String]) {
        songs = []
        albums = []
        artists = []
        singers = []
        self.problems = problems
        songsByID = [:]
        albumsByID = [:]
        artistsByID = [:]
        songIDsBySinger = [:]
        songIDsByPerson = [:]
    }

    private init(seed: SeedFile) {
        var problems: [String] = []

        var people: [Person.ID: Person] = [:]
        for singer in seed.singers {
            people[singer.slug] = Person(id: singer.slug, name: singer.name, imageFileName: singer.imageFileName)
        }
        var knownCredits: Set<CreditKey> = []
        for writer in seed.writers {
            guard let role = Role(rawValue: writer.contribution) else {
                problems.append("Writer \(writer.slug) has unknown contribution \"\(writer.contribution)\"")
                continue
            }
            knownCredits.insert(CreditKey(personID: writer.slug, role: role))
            if let person = people[writer.slug] {
                if person.name != writer.name {
                    problems.append("\(writer.slug) is named both \"\(person.name)\" and \"\(writer.name)\"")
                }
            } else {
                people[writer.slug] = Person(id: writer.slug, name: writer.name, imageFileName: nil)
            }
        }

        var songs: [Song] = []
        var albums: [Album] = []
        var artists: [Artist] = []
        var seenSongIDs: Set<Song.ID> = []

        for seedArtist in seed.artists {
            let artistID = seedArtist.slug ?? Self.slug(for: seedArtist.name)
            var artistAlbumIDs: [Album.ID] = []
            var artistSongIDs: [Song.ID] = []

            for seedAlbum in seedArtist.albums ?? [] {
                var albumSongs: [Song] = []
                for seedSong in seedAlbum.songs ?? [] {
                    guard seenSongIDs.insert(seedSong.slug).inserted else {
                        problems.append("Song \(seedSong.slug) appears more than once")
                        continue
                    }

                    var singer: Person?
                    if let singerID = seedSong.singer {
                        singer = people[singerID]
                        if singer == nil {
                            problems.append("Song \(seedSong.slug) has unknown singer \(singerID)")
                        }
                    }

                    var credits: [Credit] = []
                    for entry in seedSong.writers ?? [] {
                        guard entry.count == 2, let role = Role(rawValue: entry[1]),
                            knownCredits.contains(CreditKey(personID: entry[0], role: role)),
                            let person = people[entry[0]]
                        else {
                            problems.append("Song \(seedSong.slug) has unknown writer \(entry)")
                            continue
                        }
                        credits.append(Credit(person: person, role: role))
                    }

                    albumSongs.append(
                        Song(
                            id: seedSong.slug,
                            title: seedSong.name,
                            sheetFileName: seedSong.fileName,
                            lyrics: seedSong.lyrics ?? "",
                            discNumber: seedSong.discNumber,
                            trackNumber: seedSong.trackNumber,
                            isCover: seedSong.songType?.lowercased() == "cover",
                            appleMusicID: seedSong.appleMusicId.flatMap { $0.isEmpty ? nil : $0 },
                            albumID: seedAlbum.slug,
                            albumTitle: seedAlbum.name,
                            albumReleaseYear: seedAlbum.releaseYear,
                            coverFileName: seedAlbum.coverArtFileName,
                            artistID: artistID,
                            artistName: seedArtist.name,
                            singer: singer,
                            credits: credits
                        ))
                }

                albumSongs.sort { ($0.discNumber ?? 0, $0.trackNumber ?? 0) < ($1.discNumber ?? 0, $1.trackNumber ?? 0) }
                songs += albumSongs
                artistAlbumIDs.append(seedAlbum.slug)
                artistSongIDs += albumSongs.map(\.id)
                albums.append(
                    Album(
                        id: seedAlbum.slug,
                        title: seedAlbum.name,
                        releaseYear: seedAlbum.releaseYear,
                        coverFileName: seedAlbum.coverArtFileName,
                        artistID: artistID,
                        artistName: seedArtist.name,
                        songIDs: albumSongs.map(\.id)
                    ))
            }

            artists.append(
                Artist(
                    id: artistID,
                    name: seedArtist.name,
                    imageFileName: seedArtist.imageFileName,
                    albumIDs: artistAlbumIDs,
                    songIDs: artistSongIDs
                ))
        }

        let songsByID = Dictionary(uniqueKeysWithValues: songs.map { ($0.id, $0) })
        var songIDsBySinger: [Person.ID: [Song.ID]] = [:]
        var songIDsByPerson: [Person.ID: [Song.ID]] = [:]
        for song in songs.sorted(by: Self.titleOrder) {
            if let singer = song.singer {
                songIDsBySinger[singer.id, default: []].append(song.id)
            }
            for personID in Set(song.credits.map(\.person.id)) {
                songIDsByPerson[personID, default: []].append(song.id)
            }
        }

        self.songs = songs.sorted(by: Self.titleOrder)
        self.albums = albums.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        self.artists = artists.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        self.singers = songIDsBySinger.keys.compactMap { people[$0] }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        self.problems = problems
        self.songsByID = songsByID
        self.albumsByID = Dictionary(uniqueKeysWithValues: albums.map { ($0.id, $0) })
        self.artistsByID = Dictionary(uniqueKeysWithValues: artists.map { ($0.id, $0) })
        self.songIDsBySinger = songIDsBySinger
        self.songIDsByPerson = songIDsByPerson
    }

    /// The artist with the most songs, whose name lists can leave out.
    public var mainArtist: Artist? {
        artists.max { $0.songIDs.count < $1.songIDs.count }
    }

    // MARK: - Lookup

    public func song(id: Song.ID) -> Song? {
        songsByID[id]
    }

    public func album(id: Album.ID) -> Album? {
        albumsByID[id]
    }

    public func artist(id: Artist.ID) -> Artist? {
        artistsByID[id]
    }

    /// In disc and track order.
    public func songs(on album: Album) -> [Song] {
        album.songIDs.compactMap { songsByID[$0] }
    }

    /// Sorted by title.
    public func songs(by artist: Artist) -> [Song] {
        artist.songIDs.compactMap { songsByID[$0] }.sorted(by: Self.titleOrder)
    }

    /// Sorted by title.
    public func songs(sungBy person: Person) -> [Song] {
        (songIDsBySinger[person.id] ?? []).compactMap { songsByID[$0] }
    }

    /// Sorted by title.
    public func songs(creditedTo person: Person) -> [Song] {
        (songIDsByPerson[person.id] ?? []).compactMap { songsByID[$0] }
    }

    // MARK: - Helpers

    static let titleOrder: @Sendable (Song, Song) -> Bool = {
        $0.title.localizedStandardCompare($1.title) == .orderedAscending
    }

    static func slug(for name: String) -> String {
        name.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }
}

struct CreditKey: Hashable {
    let personID: Person.ID
    let role: Role
}

extension Catalog {
    /// The catalog generated into this package's `seeds.json` by `pnpm xcode`.
    public static let bundled: Catalog = {
        guard let url = Bundle.module.url(forResource: "seeds", withExtension: "json") else {
            return Catalog(problems: ["seeds.json is missing from the DeadSheetsKit bundle"])
        }
        do {
            return try Catalog(seedData: Data(contentsOf: url))
        } catch {
            return Catalog(problems: ["seeds.json could not be decoded: \(error)"])
        }
    }()
}

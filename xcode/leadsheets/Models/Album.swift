import Foundation
import SwiftData

@Model
class Album {
    #Index<Album>([\.slug])

    @Attribute(.unique) var id: UUID
    var name: String
    var slug: String?
    var releaseYear: Int?
    var coverArtFileName: String? // For album artwork

    var artist: Artist?

    @Relationship(inverse: \Song.album)
    var songs: [Song]?

    var sortedSongs: [Song] {
        songs?.sorted { ($0.discNumber ?? 0, $0.trackNumber ?? 0) < ($1.discNumber ?? 0, $1.trackNumber ?? 0) } ?? []
    }

    init(name: String, slug: String? = nil, releaseYear: Int? = nil, coverArtFileName: String? = nil, artist: Artist? = nil) {
        self.id = UUID()
        self.name = name
        self.slug = slug
        self.releaseYear = releaseYear
        self.coverArtFileName = coverArtFileName
        self.artist = artist
    }
}

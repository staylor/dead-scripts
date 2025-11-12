import Foundation
import SwiftData

@Model
class Song {
    @Attribute(.unique) var id: UUID
    var name: String
    var fileName: String // PDF file name
    var lyrics: String?
    var trackNumber: Int?
    var discNumber: Int?
    var dateAdded: Date
    var songType: String?
    
    // Relationships
    var album: Album?
    var artist: Artist?
    var singer: Singer?
    
    // Computed property for PDF URL
    var pdfURL: URL? {
        Bundle.main.url(forResource: fileName.replacingOccurrences(of: ".pdf", with: ""), withExtension: "pdf")
    }
    
    init(
        name: String,
        fileName: String,
        lyrics: String? = nil,
        trackNumber: Int? = nil,
        discNumber: Int? = nil,
        songType: String? = nil,
        album: Album? = nil,
        artist: Artist? = nil,
        singer: Singer? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.fileName = fileName
        self.lyrics = lyrics
        self.trackNumber = trackNumber
        self.discNumber = discNumber
        self.songType = songType
        self.dateAdded = Date()
        self.album = album
        self.artist = artist
        self.singer = singer
    }
}

@Model
class Singer {
    @Attribute(.unique) var id: UUID
    var name: String
    var imageFileName: String? // For artist photos
    
    @Relationship(inverse: \Song.singer)
    var songs: [Song]?
    
    init(name: String, imageFileName: String? = nil) {
        self.id = UUID()
        self.name = name
        self.imageFileName = imageFileName
    }
}

@Model
class Artist {
    @Attribute(.unique) var id: UUID
    var name: String
    var imageFileName: String? // For artist photos
    
    @Relationship(inverse: \Song.artist)
    var songs: [Song]?
    
    @Relationship(inverse: \Album.artist)
    var albums: [Album]?
    
    init(name: String, imageFileName: String? = nil) {
        self.id = UUID()
        self.name = name
        self.imageFileName = imageFileName
    }
}

@Model
class Album {
    @Attribute(.unique) var id: UUID
    var name: String
    var releaseYear: Int?
    var coverArtFileName: String? // For album artwork
    
    var artist: Artist?
    
    @Relationship(inverse: \Song.album)
    var songs: [Song]?
    
    var sortedSongs: [Song] {
        songs?.sorted { ($0.discNumber ?? 0, $0.trackNumber ?? 0) < ($1.discNumber ?? 0, $1.trackNumber ?? 0) } ?? []
    }
    
    init(name: String, releaseYear: Int? = nil, coverArtFileName: String? = nil, artist: Artist? = nil) {
        self.id = UUID()
        self.name = name
        self.releaseYear = releaseYear
        self.coverArtFileName = coverArtFileName
        self.artist = artist
    }
}

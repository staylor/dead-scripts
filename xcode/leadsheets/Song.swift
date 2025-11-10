import Foundation
import SwiftData

@Model
class Song {
    @Attribute(.unique) var id: UUID
    var name: String
    var fileName: String // PDF file name
    var lyrics: String?
    var duration: TimeInterval? // In seconds
    var trackNumber: Int?
    var diskNumber: Int?
    var releaseYear: Int?
    var dateAdded: Date
    
    // Relationships
    var album: Album?
    var artist: Artist?
    
    @Relationship(deleteRule: .cascade, inverse: \Tag.songs)
    var tags: [Tag]?
    
    // Computed property for PDF URL
    var pdfURL: URL? {
        Bundle.main.url(forResource: fileName.replacingOccurrences(of: ".pdf", with: ""), withExtension: "pdf")
    }
    
    init(
        name: String,
        fileName: String,
        lyrics: String? = nil,
        duration: TimeInterval? = nil,
        trackNumber: Int? = nil,
        diskNumber: Int? = nil,
        releaseYear: Int? = nil,
        album: Album? = nil,
        artist: Artist? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.fileName = fileName
        self.lyrics = lyrics
        self.duration = duration
        self.trackNumber = trackNumber
        self.diskNumber = diskNumber
        self.releaseYear = releaseYear
        self.dateAdded = Date()
        self.album = album
        self.artist = artist
    }
}

@Model
class Artist {
    @Attribute(.unique) var id: UUID
    var name: String
    var biography: String?
    var imageFileName: String? // For artist photos
    var website: String?
    
    @Relationship(deleteRule: .cascade, inverse: \Song.artist)
    var songs: [Song]?
    
    @Relationship(deleteRule: .cascade, inverse: \Album.artist)
    var albums: [Album]?
    
    init(name: String, biography: String? = nil, imageFileName: String? = nil, website: String? = nil) {
        self.id = UUID()
        self.name = name
        self.biography = biography
        self.imageFileName = imageFileName
        self.website = website
    }
}

@Model
class Album {
    @Attribute(.unique) var id: UUID
    var name: String
    var releaseDate: Date?
    var coverArtFileName: String? // For album artwork
    var recordLabel: String?
    
    var artist: Artist?
    
    @Relationship(deleteRule: .cascade, inverse: \Song.album)
    var songs: [Song]?
    
    var sortedSongs: [Song] {
        songs?.sorted { ($0.diskNumber ?? 0, $0.trackNumber ?? 0) < ($1.diskNumber ?? 0, $1.trackNumber ?? 0) } ?? []
    }
    
    init(name: String, releaseDate: Date? = nil, coverArtFileName: String? = nil, recordLabel: String? = nil, artist: Artist? = nil) {
        self.id = UUID()
        self.name = name
        self.releaseDate = releaseDate
        self.coverArtFileName = coverArtFileName
        self.recordLabel = recordLabel
        self.artist = artist
    }
}

@Model
class Tag {
    @Attribute(.unique) var name: String
    var color: String? // Hex color for UI
    
    @Relationship(deleteRule: .nullify)
    var songs: [Song]?
    
    init(name: String, color: String? = nil) {
        self.name = name
        self.color = color
    }
}

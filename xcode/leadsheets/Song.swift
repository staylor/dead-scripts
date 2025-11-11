import Foundation
import SwiftData

@Model
class Song {
    @Attribute(.unique) var id: UUID
    var name: String
    var fileName: String // PDF file name
    var lyrics: String?
    var trackNumber: Int?
    var diskNumber: Int?
    var releaseYear: Int?
    var dateAdded: Date
    var songType: String?
    
    // Relationships
    var album: Album?
    var artist: Artist?
    var singer: Singer?
    
    @Relationship(inverse: \Tag.songs)
    var tags: [Tag]?
    
    // Computed property for PDF URL
    var pdfURL: URL? {
        Bundle.main.url(forResource: fileName.replacingOccurrences(of: ".pdf", with: ""), withExtension: "pdf")
    }
    
    init(
        name: String,
        fileName: String,
        lyrics: String? = nil,
        trackNumber: Int? = nil,
        diskNumber: Int? = nil,
        releaseYear: Int? = nil,
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
        self.diskNumber = diskNumber
        self.releaseYear = releaseYear
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
    
    @Relationship(inverse: \Song.singer)
    var songs: [Song]?
    
    init(name: String) {
        self.id = UUID()
        self.name = name
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
    var releaseDate: Date?
    var coverArtFileName: String? // For album artwork
    
    var artist: Artist?
    
    @Relationship(inverse: \Song.album)
    var songs: [Song]?
    
    var sortedSongs: [Song] {
        songs?.sorted { ($0.diskNumber ?? 0, $0.trackNumber ?? 0) < ($1.diskNumber ?? 0, $1.trackNumber ?? 0) } ?? []
    }
    
    init(name: String, releaseDate: Date? = nil, coverArtFileName: String? = nil, artist: Artist? = nil) {
        self.id = UUID()
        self.name = name
        self.releaseDate = releaseDate
        self.coverArtFileName = coverArtFileName
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

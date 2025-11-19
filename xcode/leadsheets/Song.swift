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
    var writers: [Writer]?

    // Computed property for PDF URL
    var pdfURL: URL? {
        Bundle.main.url(forResource: fileName.replacingOccurrences(of: ".pdf", with: ""), withExtension: "pdf")
    }

    // Computed property for image URL (for tvOS)
    var imageURL: URL? {
        Bundle.main.url(forResource: fileName.replacingOccurrences(of: ".pdf", with: ""), withExtension: "png")
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
        singer: Singer? = nil,
        writers: [Writer]? = nil,
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
        self.writers = writers
    }
}

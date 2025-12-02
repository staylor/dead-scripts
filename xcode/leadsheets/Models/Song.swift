import Foundation
import SwiftData

@Model
class Song {
    #Index<Song>([\.slug])
    @Attribute(.unique) var id: UUID
    var name: String
    var slug: String?
    var fileName: String // PDF file name
    var lyrics: String?
    var trackNumber: Int?
    var discNumber: Int?
    var songType: String?
    var appleMusicId: String?

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
        slug: String? = nil,
        fileName: String,
        lyrics: String? = nil,
        trackNumber: Int? = nil,
        discNumber: Int? = nil,
        songType: String? = nil,
        album: Album? = nil,
        artist: Artist? = nil,
        singer: Singer? = nil,
        writers: [Writer]? = nil,
        appleMusicId: String? = nil,
    ) {
        self.id = UUID()
        self.name = name
        self.slug = slug
        self.fileName = fileName
        self.lyrics = lyrics
        self.trackNumber = trackNumber
        self.discNumber = discNumber
        self.songType = songType
        self.album = album
        self.artist = artist
        self.singer = singer
        self.writers = writers
        self.appleMusicId = appleMusicId
    }
}

// MARK: - Display Formatting
extension Song {
    var singerDisplayText: String {
        guard let singer = singer else {
            return ""
        }
        return "Original singer: \(singer.name)"
    }
    
    /// Formats the writers' names and contributions for display
    /// Groups by contribution type (e.g., "Music: Garcia & Weir, Lyrics: Hunter")
    /// If music and lyrics have the same writers, combines them as "Music & Lyrics"
    var writersDisplayText: String {
        guard let writers = writers, !writers.isEmpty else {
            return "Unknown Writer"
        }
        
        // Group writers by contribution type
        let groupedByContribution = Dictionary(grouping: writers) { $0.contribution }
        
        // Get writer names for music and lyrics
        let musicWriters = groupedByContribution["music"]?.map { $0.name }.sorted() ?? []
        let lyricsWriters = groupedByContribution["lyrics"]?.map { $0.name }.sorted() ?? []
        
        // Check if music and lyrics have the same writers
        let hasSameWriters = !musicWriters.isEmpty && !lyricsWriters.isEmpty && musicWriters == lyricsWriters
        
        var contributionStrings: [String] = []
        
        if hasSameWriters {
            // Combine music and lyrics into one attribution
            let namesString = formatWriterNames(musicWriters)
            contributionStrings.append("Music & Lyrics: \(namesString)")
            
            // Add any other contribution types
            for (contribution, writersForContribution) in groupedByContribution.sorted(by: { $0.key < $1.key }) {
                guard contribution != "music" && contribution != "lyrics" else { continue }
                
                let capitalized = contribution.prefix(1).uppercased() + contribution.dropFirst()
                let writerNames = writersForContribution.map { $0.name }.sorted()
                let namesString = formatWriterNames(writerNames)
                
                contributionStrings.append("\(capitalized): \(namesString)")
            }
        } else {
            // Keep music and lyrics separate
            for (contribution, writersForContribution) in groupedByContribution.sorted(by: { $0.key < $1.key }) {
                let capitalized = contribution.prefix(1).uppercased() + contribution.dropFirst()
                let writerNames = writersForContribution.map { $0.name }.sorted()
                let namesString = formatWriterNames(writerNames)
                
                contributionStrings.append("\(capitalized): \(namesString)")
            }
        }
        
        return contributionStrings.joined(separator: ", ")
    }
    
    /// Formats a list of writer names with proper grammar (commas and ampersands)
    private func formatWriterNames(_ names: [String]) -> String {
        switch names.count {
        case 0:
            return ""
        case 1:
            return names[0]
        case 2:
            return names.joined(separator: " & ")
        default:
            // 3 or more: use commas between all but the last, then " & " for the last
            let allButLast = names.dropLast().joined(separator: ", ")
            return "\(allButLast) & \(names.last!)"
        }
    }
}

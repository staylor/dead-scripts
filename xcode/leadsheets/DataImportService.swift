import Foundation
import SwiftData

/// Service responsible for importing seed data from JSON files into SwiftData
actor DataImportService {
    // MARK: - Enhanced JSON Structure (for future imports)
    
    /// Enhanced structure with additional metadata
    struct EnhancedJSONFormat: Codable {
        let artists: [EnhancedArtistJSON]
    }
    
    struct EnhancedArtistJSON: Codable {
        let name: String
        let imageFileName: String?  // Can include path like "artists/taylor_swift.jpg"
        let albums: [EnhancedAlbumJSON]?
    }
    
    struct EnhancedAlbumJSON: Codable {
        let name: String
        let releaseDate: String? // ISO 8601 format
        let coverArtFileName: String?  // Can include path like "album_covers/1989.jpg"
        let songs: [EnhancedSongJSON]?
    }
    
    struct EnhancedSongJSON: Codable {
        let name: String
        let fileName: String  // Can include path like "audio/shake_it_off.mp3"
        let lyrics: String?
        let releaseYear: Int?
        let tags: [String]?
    }
    
    // MARK: - Import Methods
    /// Import from enhanced JSON format (with additional metadata like release dates, tags, etc.)
    func importEnhancedJSON(from fileName: String, into context: ModelContext) async throws {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            throw ImportError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let library = try JSONDecoder().decode(EnhancedJSONFormat.self, from: data)
        
        var tagCache: [String: Tag] = [:]
        
        // Process each artist
        for artistData in library.artists {
            // Create artist once
            let artist = Artist(
                name: artistData.name,
                imageFileName: artistData.imageFileName
            )
            context.insert(artist)
            
            // Process albums for this artist
            guard let albums = artistData.albums else { continue }
            for albumData in albums {
                // Create album once
                let releaseDate = albumData.releaseDate.flatMap { ISO8601DateFormatter().date(from: $0) }
                let album = Album(
                    name: albumData.name,
                    releaseDate: releaseDate,
                    coverArtFileName: albumData.coverArtFileName,
                    artist: artist
                )
                context.insert(album)
                
                // Process songs for this album
                guard let songs = albumData.songs else { continue }
                for songData in songs {
                    let song = Song(
                        name: songData.name,
                        fileName: songData.fileName,
                        lyrics: songData.lyrics,
                        releaseYear: songData.releaseYear,
                        album: album,
                        artist: artist
                    )
                    context.insert(song)
                    
                    // Handle tags
                    if let tagNames = songData.tags {
                        var tags: [Tag] = []
                        for tagName in tagNames {
                            if let cached = tagCache[tagName] {
                                tags.append(cached)
                            } else {
                                let tag = Tag(name: tagName)
                                context.insert(tag)
                                tagCache[tagName] = tag
                                tags.append(tag)
                            }
                        }
                        song.tags = tags
                    }
                }
            }
        }
        
        try context.save()
    }
    
    enum ImportError: Error {
        case fileNotFound
        case invalidFormat
    }
}

// MARK: - Resource Path Helpers
extension DataImportService {
    
    /// Helper to construct full paths for different resource types
    enum ResourcePath {
        static func forArtistImage(_ fileName: String) -> String {
            if fileName.contains("/") {
                return fileName
            }
            return "artists/\(fileName)"
        }
        
        static func forAlbumCover(_ fileName: String) -> String {
            if fileName.contains("/") {
                return fileName
            }
            return "albums/\(fileName)"
        }
    }
}

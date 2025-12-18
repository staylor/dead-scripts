import Foundation
import SwiftData

/// Service responsible for importing seed data from JSON files into SwiftData
actor DataImportService {
    // MARK: - Enhanced JSON Structure (for future imports)
    
    /// Enhanced structure with additional metadata
    struct EnhancedJSONFormat: Codable {
        let artists: [EnhancedArtistJSON]
        let singers: [EnhancedSingerJSON]
        let writers: [EnhancedWriterJSON]
    }
    
    struct EnhancedArtistJSON: Codable {
        let name: String
        let imageFileName: String?  // Can include path like "artists/taylor_swift.jpg"
        let albums: [EnhancedAlbumJSON]?
    }
    
    struct EnhancedAlbumJSON: Codable {
        let name: String
        let slug: String
        let releaseYear: Int?
        let coverArtFileName: String?  // Can include path like "album_covers/1989.jpg"
        let songs: [EnhancedSongJSON]?
    }
    
    struct EnhancedSingerJSON: Codable {
        let name: String
        let slug: String
        let imageFileName: String?
    }

    struct EnhancedWriterJSON: Codable {
        let name: String
        let slug: String
        let contribution: String
    }
    
    struct EnhancedSongJSON: Codable {
        let name: String
        let slug: String
        let fileName: String  // Can include path like "audio/shake_it_off.mp3"
        let lyrics: String?
        let singer: String?
        let writers: [[String]]?
        let songType: String?
        let discNumber: Int?
        let trackNumber: Int?
        let appleMusicId: String?
    }
    
    // MARK: - Import Methods
    /// Import from enhanced JSON format (with additional metadata like release dates, etc.)
    func importEnhancedJSON(from fileName: String, into context: ModelContext) async throws {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            throw ImportError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let library = try JSONDecoder().decode(EnhancedJSONFormat.self, from: data)
        
        var singerCache: [String: Singer] = [:]
        for singerData in library.singers {
            let singer = Singer(
                name: singerData.name,
                imageFileName: singerData.imageFileName,
            )
            singerCache[singerData.slug] = singer
            context.insert(singer)
        }
        var writerCache: [String: Writer] = [:]
        for writerData in library.writers {
            let writer = Writer(
                name: writerData.name,
                contribution: writerData.contribution
            )
            writerCache[writerData.slug + writerData.contribution] = writer
            context.insert(writer)
        }
        
        // Process each artist
        for artistData in library.artists {
            // Create artist once
            let artist = Artist(
                name: artistData.name,
                imageFileName: artistData.imageFileName.map { ResourcePath.forArtistImage($0) }
            )
            context.insert(artist)
            
            // Process albums for this artist
            guard let albums = artistData.albums else { continue }
            for albumData in albums {
                // Create album once
                let album = Album(
                    name: albumData.name,
                    slug: albumData.slug,
                    releaseYear: albumData.releaseYear,
                    coverArtFileName: albumData.coverArtFileName,
                    artist: artist
                )
                context.insert(album)
                
                // Process songs for this album
                guard let songs = albumData.songs else { continue }
                for songData in songs {
                    var singer: Singer? = nil
                    if let slug = songData.singer, let cached = singerCache[slug] {
                        singer = cached
                    }
                    var writers: [Writer] = []
                    if let entries = songData.writers {
                        for writer in entries where writer.count >= 2 {
                            if let cached = writerCache[writer[0] + writer[1]] {
                                writers.append(cached)
                            }
                        }
                    }
                    let song = Song(
                        name: songData.name,
                        slug: songData.slug,
                        fileName: songData.fileName,
                        lyrics: songData.lyrics,
                        trackNumber: songData.trackNumber,
                        discNumber: songData.discNumber,
                        songType: songData.songType,
                        album: album,
                        artist: artist,
                        singer: singer,
                        writers: writers,
                        appleMusicId: songData.appleMusicId
                    )
                    context.insert(song)
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
    }
}

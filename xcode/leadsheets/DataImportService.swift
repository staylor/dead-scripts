import Foundation
import SwiftData

/// Service responsible for importing seed data from JSON files into SwiftData
actor DataImportService {
    
    // MARK: - Legacy JSON Structure (for migration)
    struct LegacySongJSON: Codable {
        let name: String
        let albumName: String
        let fileName: String
        let lyrics: String?
    }
    
    // MARK: - New JSON Structure (for future imports)
    struct SongImportJSON: Codable {
        let name: String
        let fileName: String
        let lyrics: String?
        let releaseYear: Int?
        
        // Nested objects
        let artist: ArtistImportJSON?
        let album: AlbumImportJSON?
        let tags: [String]?
    }
    
    struct ArtistImportJSON: Codable {
        let name: String
        let imageFileName: String?
    }
    
    struct AlbumImportJSON: Codable {
        let name: String
        let releaseDate: String? // ISO 8601 format
        let coverArtFileName: String?
    }
    
    // MARK: - Import Methods
    
    /// Import from legacy JSON format (your current songs.json)
    func importLegacyJSON(from fileName: String, into context: ModelContext) async throws {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            throw ImportError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let legacySongs = try JSONDecoder().decode([LegacySongJSON].self, from: data)
        
        // Create a cache to avoid duplicate artists/albums
        var artistCache: [String: Artist] = [:]
        var albumCache: [String: Album] = [:]
        
        for legacySong in legacySongs {
            // Get or create artist (using album name as temporary artist name)
            let artistName = legacySong.albumName // You can update this later
            let artist: Artist
            if let cached = artistCache[artistName] {
                artist = cached
            } else {
                artist = Artist(name: artistName)
                context.insert(artist)
                artistCache[artistName] = artist
            }
            
            // Get or create album
            let album: Album
            if let cached = albumCache[legacySong.albumName] {
                album = cached
            } else {
                album = Album(name: legacySong.albumName, artist: artist)
                context.insert(album)
                albumCache[legacySong.albumName] = album
            }
            
            // Create song
            let song = Song(
                name: legacySong.name,
                fileName: legacySong.fileName,
                lyrics: legacySong.lyrics,
                album: album,
                artist: artist
            )
            context.insert(song)
        }
        
        try context.save()
    }
    
    /// Import from new structured JSON format
    func importStructuredJSON(from fileName: String, into context: ModelContext) async throws {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            throw ImportError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let importSongs = try JSONDecoder().decode([SongImportJSON].self, from: data)
        
        var artistCache: [String: Artist] = [:]
        var albumCache: [String: Album] = [:]
        var tagCache: [String: Tag] = [:]
        
        for importSong in importSongs {
            // Handle artist
            var artist: Artist?
            if let artistData = importSong.artist {
                if let cached = artistCache[artistData.name] {
                    artist = cached
                } else {
                    artist = Artist(
                        name: artistData.name,
                        imageFileName: artistData.imageFileName
                    )
                    context.insert(artist!)
                    artistCache[artistData.name] = artist
                }
            }
            
            // Handle album
            var album: Album?
            if let albumData = importSong.album {
                let cacheKey = "\(albumData.name)-\(artist?.name ?? "")"
                if let cached = albumCache[cacheKey] {
                    album = cached
                } else {
                    let releaseDate = albumData.releaseDate.flatMap { ISO8601DateFormatter().date(from: $0) }
                    album = Album(
                        name: albumData.name,
                        releaseDate: releaseDate,
                        coverArtFileName: albumData.coverArtFileName,
                        artist: artist
                    )
                    context.insert(album!)
                    albumCache[cacheKey] = album
                }
            }
            
            // Create song
            let song = Song(
                name: importSong.name,
                fileName: importSong.fileName,
                lyrics: importSong.lyrics,
                releaseYear: importSong.releaseYear,
                album: album,
                artist: artist
            )
            context.insert(song)
            
            // Handle tags
            if let tagNames = importSong.tags {
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
        
        try context.save()
    }
    
    enum ImportError: Error {
        case fileNotFound
        case invalidFormat
    }
}

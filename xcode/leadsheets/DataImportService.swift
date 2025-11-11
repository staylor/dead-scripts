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
        let releaseYear: Int?
        let coverArtFileName: String?  // Can include path like "album_covers/1989.jpg"
        let songs: [EnhancedSongJSON]?
    }
    
    struct EnhancedSongJSON: Codable {
        let name: String
        let fileName: String  // Can include path like "audio/shake_it_off.mp3"
        let lyrics: String?
        let singer: String?
        let tags: [String]?
        let songType: String?
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
        var singerCache: [String: Singer] = [:]
        
        // Pre-populate caches with existing data from database
        let existingTags = try context.fetch(FetchDescriptor<Tag>())
        for tag in existingTags {
            tagCache[tag.name] = tag
        }
        
        let existingSingers = try context.fetch(FetchDescriptor<Singer>())
        for singer in existingSingers {
            singerCache[singer.name] = singer
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
                    releaseYear: albumData.releaseYear,
                    coverArtFileName: albumData.coverArtFileName,
                    artist: artist
                )
                context.insert(album)
                
                // Process songs for this album
                guard let songs = albumData.songs else { continue }
                for songData in songs {
                    var singer: Singer? = nil
                    if let singerName = songData.singer {
                        if let cached = singerCache[singerName] {
                            singer = cached
                        } else {
                            singer = Singer(name: singerName)
                            context.insert(singer!)
                            singerCache[singerName] = singer
                        }
                    }
                    let song = Song(
                        name: songData.name,
                        fileName: songData.fileName,
                        lyrics: songData.lyrics,
                        songType: songData.songType,
                        album: album,
                        artist: artist,
                        singer: singer
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
    
    // MARK: - Deduplication Methods
    
    /// Remove duplicate singers from the database, keeping only one instance per name
    func deduplicateSingers(in context: ModelContext) async throws {
        let allSingers = try context.fetch(FetchDescriptor<Singer>())
        
        // Group singers by name
        var singersByName: [String: [Singer]] = [:]
        for singer in allSingers {
            singersByName[singer.name, default: []].append(singer)
        }
        
        // For each group with duplicates, keep the first one and merge relationships
        for (_, singers) in singersByName where singers.count > 1 {
            guard let primarySinger = singers.first else { continue }
            
            // Merge all songs to the primary singer
            for duplicateSinger in singers.dropFirst() {
                if let songs = duplicateSinger.songs {
                    for song in songs {
                        song.singer = primarySinger
                    }
                }
                // Delete the duplicate
                context.delete(duplicateSinger)
            }
        }
        
        try context.save()
    }
    
    /// Remove duplicate tags from the database, keeping only one instance per name
    func deduplicateTags(in context: ModelContext) async throws {
        let allTags = try context.fetch(FetchDescriptor<Tag>())
        
        // Group tags by name
        var tagsByName: [String: [Tag]] = [:]
        for tag in allTags {
            tagsByName[tag.name, default: []].append(tag)
        }
        
        // For each group with duplicates, keep the first one and merge relationships
        for (_, tags) in tagsByName where tags.count > 1 {
            guard let primaryTag = tags.first else { continue }
            
            // Merge all songs to the primary tag
            for duplicateTag in tags.dropFirst() {
                if let songs = duplicateTag.songs {
                    for song in songs {
                        var songTags = song.tags ?? []
                        // Remove the duplicate tag if present
                        songTags.removeAll { $0.name == duplicateTag.name }
                        // Add the primary tag if not already present
                        if !songTags.contains(where: { $0.name == primaryTag.name }) {
                            songTags.append(primaryTag)
                        }
                        song.tags = songTags
                    }
                }
                // Delete the duplicate
                context.delete(duplicateTag)
            }
        }
        
        try context.save()
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

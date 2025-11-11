import SwiftData
import Foundation

/// Helper class for common database operations
@MainActor
class SongDataManager {
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Create
    
    func addSong(
        name: String,
        fileName: String,
        lyrics: String? = nil,
        artist: Artist? = nil,
        album: Album? = nil
    ) {
        let song = Song(
            name: name,
            fileName: fileName,
            lyrics: lyrics,
            album: album,
            artist: artist
        )
        modelContext.insert(song)
        try? modelContext.save()
    }
    
    func addArtist(name: String) -> Artist {
        let artist = Artist(name: name)
        modelContext.insert(artist)
        try? modelContext.save()
        return artist
    }
    
    func addAlbum(name: String, artist: Artist? = nil) -> Album {
        let album = Album(name: name, artist: artist)
        modelContext.insert(album)
        try? modelContext.save()
        return album
    }
    
    // MARK: - Read
    
    func fetchAllSongs() -> [Song] {
        let descriptor = FetchDescriptor<Song>(sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetchSongs(by artist: Artist) -> [Song] {
        // Fetch all songs and filter in memory due to predicate limitations with optional relationships
        let allSongs = fetchAllSongs()
        return allSongs.filter { $0.artist?.id == artist.id }
    }
    
    func fetchSongs(in album: Album) -> [Song] {
        // Fetch all songs and filter in memory due to predicate limitations with optional relationships
        let allSongs = fetchAllSongs()
        return allSongs.filter { $0.album?.id == album.id }
            .sorted { ($0.trackNumber ?? 0) < ($1.trackNumber ?? 0) }
    }
    
    func searchSongs(query: String) -> [Song] {
        guard !query.isEmpty else { return fetchAllSongs() }
        
        let allSongs = fetchAllSongs()
        return allSongs.filter { song in
            song.name.localizedCaseInsensitiveContains(query) ||
            song.artist?.name.localizedCaseInsensitiveContains(query) == true ||
            song.album?.name.localizedCaseInsensitiveContains(query) == true ||
            song.lyrics?.localizedCaseInsensitiveContains(query) == true
        }
    }
    
    func fetchAllArtists() -> [Artist] {
        let descriptor = FetchDescriptor<Artist>(sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetchAllAlbums() -> [Album] {
        let descriptor = FetchDescriptor<Album>(sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    // MARK: - Update
    
    func updateSong(_ song: Song, name: String? = nil, lyrics: String? = nil) {
        if let name = name {
            song.name = name
        }
        if let lyrics = lyrics {
            song.lyrics = lyrics
        }
        try? modelContext.save()
    }
    
    func assignArtist(_ artist: Artist, to song: Song) {
        song.artist = artist
        try? modelContext.save()
    }
    
    func assignAlbum(_ album: Album, to song: Song) {
        song.album = album
        try? modelContext.save()
    }
    
    // MARK: - Delete
    
    func deleteSong(_ song: Song) {
        modelContext.delete(song)
        try? modelContext.save()
    }
    
    func deleteArtist(_ artist: Artist) {
        // This will cascade delete songs if configured
        modelContext.delete(artist)
        try? modelContext.save()
    }
    
    func deleteAlbum(_ album: Album) {
        modelContext.delete(album)
        try? modelContext.save()
    }
    
    // MARK: - Statistics
    
    func getSongCount() -> Int {
        let descriptor = FetchDescriptor<Song>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
    
    func getArtistCount() -> Int {
        let descriptor = FetchDescriptor<Artist>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
    
    func getAlbumCount() -> Int {
        let descriptor = FetchDescriptor<Album>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
    
    // MARK: - Batch Operations
    
    func deleteAllSongs() {
        let songs = fetchAllSongs()
        songs.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }
    
    func deleteAllData() {
        // Delete all songs, artists, albums, and tags
        fetchAllSongs().forEach { modelContext.delete($0) }
        fetchAllArtists().forEach { modelContext.delete($0) }
        fetchAllAlbums().forEach { modelContext.delete($0) }
        
        let descriptor = FetchDescriptor<Tag>()
        if let tags = try? modelContext.fetch(descriptor) {
            tags.forEach { modelContext.delete($0) }
        }
        
        try? modelContext.save()
    }
    
    // MARK: - Utility
    
    func findOrCreateArtist(name: String) -> Artist {
        let descriptor = FetchDescriptor<Artist>(
            predicate: #Predicate { artist in
                artist.name == name
            }
        )
        
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        
        return addArtist(name: name)
    }
    
    func findOrCreateAlbum(name: String, artist: Artist? = nil) -> Album {
        // Fetch all albums and filter in memory due to predicate limitations
        let allAlbums = fetchAllAlbums()
        
        let existing = allAlbums.first { album in
            album.name == name && album.artist?.id == artist?.id
        }
        
        if let existing = existing {
            return existing
        }
        
        return addAlbum(name: name, artist: artist)
    }
}

// MARK: - Usage Examples

/*
 Example usage in a SwiftUI view:
 
 struct ExampleView: View {
     @Environment(\.modelContext) private var modelContext
     
     var songManager: SongDataManager {
         SongDataManager(modelContext: modelContext)
     }
     
     var body: some View {
         VStack {
             Button("Add Sample Song") {
                 let artist = songManager.findOrCreateArtist(name: "Miles Davis")
                 let album = songManager.findOrCreateAlbum(name: "Kind of Blue", artist: artist)
                 
                 songManager.addSong(
                     name: "So What",
                     fileName: "so-what.pdf",
                     lyrics: "Sample lyrics...",
                     artist: artist,
                     album: album
                 )
             }
             
             Button("Show Stats") {
                 print("Total songs: \(songManager.getSongCount())")
                 print("Total artists: \(songManager.getArtistCount())")
             }
         }
     }
 }
 */

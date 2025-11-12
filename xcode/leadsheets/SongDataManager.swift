import SwiftData
import Foundation

/// Helper class for common database operations
@MainActor
class SongDataManager {
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Read
    
    func fetchAllSongs() -> [Song] {
        let descriptor = FetchDescriptor<Song>(sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetchAllArtists() -> [Artist] {
        let descriptor = FetchDescriptor<Artist>(sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetchAllAlbums() -> [Album] {
        let descriptor = FetchDescriptor<Album>(sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetchAllSingers() -> [Singer] {
        let descriptor = FetchDescriptor<Singer>(sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
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
    
    func deleteAllData() {
        // Delete all songs, artists, albums
        fetchAllSongs().forEach { modelContext.delete($0) }
        fetchAllArtists().forEach { modelContext.delete($0) }
        fetchAllAlbums().forEach { modelContext.delete($0) }
        fetchAllSingers().forEach { modelContext.delete($0) }
        
        try? modelContext.save()
    }
}


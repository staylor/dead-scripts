import SwiftUI
import SwiftData

// MARK: - Advanced Query Examples

// Example 1: Filter by artist
struct ArtistSongsView: View {
    let artist: Artist
    
    @Query private var songs: [Song]
    
    init(artist: Artist) {
        self.artist = artist
        // Query songs by specific artist
        _songs = Query(filter: #Predicate<Song> { song in
            song.artist?.id == artist.id
        }, sort: \Song.name)
    }
    
    var body: some View {
        List(songs) { song in
            Text(song.name)
        }
    }
}

// Example 2: Filter by year range
struct SongsByYearView: View {
    let startYear: Int
    let endYear: Int
    
    @Query private var songs: [Song]
    
    init(startYear: Int, endYear: Int) {
        self.startYear = startYear
        self.endYear = endYear
        
        _songs = Query(filter: #Predicate<Song> { song in
            if let year = song.releaseYear {
                return year >= startYear && year <= endYear
            }
            return false
        }, sort: \Song.releaseYear)
    }
    
    var body: some View {
        List(songs) { song in
            HStack {
                Text(song.name)
                Spacer()
                if let year = song.releaseYear {
                    Text("\(year)")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// Example 3: Filter by tag
struct SongsByTagView: View {
    let tagName: String
    
    @Query private var allSongs: [Song]
    
    var filteredSongs: [Song] {
        allSongs.filter { song in
            song.tags?.contains(where: { $0.name == tagName }) == true
        }
    }
    
    var body: some View {
        List(filteredSongs) { song in
            Text(song.name)
        }
    }
}

// Example 4: Complex search across multiple fields
struct AdvancedSearchView: View {
    @State private var searchText = ""
    @Query private var allSongs: [Song]
    
    var searchResults: [Song] {
        guard !searchText.isEmpty else { return [] }
        
        return allSongs.filter { song in
            // Search in song name
            song.name.localizedCaseInsensitiveContains(searchText) ||
            // Search in artist name
            song.artist?.name.localizedCaseInsensitiveContains(searchText) == true ||
            // Search in album name
            song.album?.name.localizedCaseInsensitiveContains(searchText) == true ||
            // Search in lyrics
            song.lyrics?.localizedCaseInsensitiveContains(searchText) == true ||
            // Search in tags
            song.tags?.contains(where: { $0.name.localizedCaseInsensitiveContains(searchText) }) == true
        }
    }
    
    var body: some View {
        List(searchResults) { song in
            VStack(alignment: .leading) {
                Text(song.name)
                    .font(.headline)
                if let artist = song.artist {
                    Text(artist.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search songs, artists, albums...")
    }
}

// Example 5: Group songs by album
struct AlbumGroupedView: View {
    @Query(sort: \Album.name) private var albums: [Album]
    
    var body: some View {
        List {
            ForEach(albums) { album in
                Section(header: Text(album.name)) {
                    ForEach(album.sortedSongs) { song in
                        HStack {
                            if let trackNumber = song.trackNumber {
                                Text("\(trackNumber)")
                                    .foregroundColor(.secondary)
                                    .frame(width: 30)
                            }
                            Text(song.name)
                        }
                    }
                }
            }
        }
    }
}

// Example 6: Recently added songs
struct RecentSongsView: View {
    @Query(
        sort: [SortDescriptor(\Song.dateAdded, order: .reverse)],
        animation: .default
    ) private var songs: [Song]
    
    var body: some View {
        List(songs.prefix(20)) { song in
            VStack(alignment: .leading) {
                Text(song.name)
                Text(song.dateAdded, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Recently Added")
    }
}

// Example 7: Statistical view
struct StatsView: View {
    @Query private var songs: [Song]
    @Query private var artists: [Artist]
    @Query private var albums: [Album]

    var body: some View {
        Form {
            Section("Library Stats") {
                LabeledContent("Total Songs", value: "\(songs.count)")
                LabeledContent("Total Artists", value: "\(artists.count)")
                LabeledContent("Total Albums", value: "\(albums.count)")
            }
            
            Section("By Artist") {
                ForEach(artists) { artist in
                    LabeledContent(artist.name, value: "\(artist.songs?.count ?? 0) songs")
                }
            }
        }
    }
}

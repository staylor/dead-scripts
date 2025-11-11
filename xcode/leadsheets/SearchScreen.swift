import SwiftUI
import SwiftData

enum SearchFilter: String, CaseIterable {
    case allSongs = "All Songs"
    case byAlbum = "By Album"
    case byArtist = "By Artist"
    case bySinger = "By Singer"
    case covers = "Covers"
}

struct SearchScreen: View {
    @Binding var searchText: String
    let songs: [Song]
    let onSelect: (Song) -> Void
    
    @State private var selectedFilter: SearchFilter = .allSongs
    @State private var selectedAlbum: Album?
    @State private var selectedArtist: Artist?
    @State private var selectedSinger: Singer?
    @State private var showingDebugMenu = false
    @Environment(\.modelContext) private var modelContext
    @Query private var albums: [Album]
    @Query private var artists: [Artist]
    @Query private var singers: [Singer]
    @Query(sort: \Song.name) private var allSongs: [Song]
    @AppStorage("hasImportedInitialData") private var hasImportedInitialData = false
    
    // Filtered albums based on search
    private var filteredAlbums: [Album] {
        if searchText.isEmpty {
            return albums.sorted { $0.name < $1.name }
        }
        return albums.filter { album in
            album.name.localizedCaseInsensitiveContains(searchText) ||
            album.artist?.name.localizedCaseInsensitiveContains(searchText) == true
        }.sorted { $0.name < $1.name }
    }
    
    // Filtered artists based on search
    private var filteredArtists: [Artist] {
        if searchText.isEmpty {
            return artists.sorted { $0.name < $1.name }
        }
        return artists.filter { artist in
            artist.name.localizedCaseInsensitiveContains(searchText)
        }.sorted { $0.name < $1.name }
    }
    
    // Filtered singers based on search
    private var filteredSingers: [Singer] {
        if searchText.isEmpty {
            return singers.sorted { $0.name < $1.name }
        }
        return singers.filter { singer in
            singer.name.localizedCaseInsensitiveContains(searchText)
        }.sorted { $0.name < $1.name }
    }
    
    // Filtered cover songs
    private var coverSongs: [Song] {
        let covers = songs.filter { $0.songType?.lowercased() == "cover" }
        if searchText.isEmpty {
            return covers.sorted { $0.name < $1.name }
        }
        return covers.filter { song in
            song.name.localizedCaseInsensitiveContains(searchText) ||
            song.artist?.name.localizedCaseInsensitiveContains(searchText) == true ||
            song.singer?.name.localizedCaseInsensitiveContains(searchText) == true
        }.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            #if os(macOS)
            // macOS: Use toolbar instead of custom header
            VStack(spacing: 0) {
                // Search Bar (macOS native style)
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search songs...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                
                // Filter Picker (macOS native style)
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(SearchFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: selectedFilter) { _, _ in
                    selectedAlbum = nil
                    selectedArtist = nil
                    selectedSinger = nil
                }
            }
            #else
            // iOS/iPadOS: Keep existing custom design
            // Title with Debug Button
            HStack {
                Text("Dead Sheets")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: {
                    showingDebugMenu = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 10)
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search songs...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SearchFilter.allCases, id: \.self) { filter in
                        Button(action: {
                            selectedFilter = filter
                            selectedAlbum = nil  // Reset selections when changing filter
                            selectedArtist = nil
                            selectedSinger = nil
                        }) {
                            Text(filter.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedFilter == filter ? Color.pink : Color(.systemGray6))
                                .foregroundColor(selectedFilter == filter ? .white : .primary)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
            #endif
            
            // Results List
            if selectedFilter == .allSongs {
                songsListView
            } else if selectedFilter == .byAlbum {
                if let selectedAlbum = selectedAlbum {
                    albumDetailView(for: selectedAlbum)
                } else {
                    albumsListView
                }
            } else if selectedFilter == .byArtist {
                if let selectedArtist = selectedArtist {
                    artistDetailView(for: selectedArtist)
                } else {
                    artistsListView
                }
            } else if selectedFilter == .bySinger {
                if let selectedSinger = selectedSinger {
                    singerDetailView(for: selectedSinger)
                } else {
                    singersListView
                }
            } else if selectedFilter == .covers {
                coversListView
            }
        }
        .alert("Debug Menu", isPresented: $showingDebugMenu) {
            Button("Reset Import Flag & Delete All Data", role: .destructive) {
                resetAllData()
            }
            Button("Re-import Data", role: .destructive) {
                Task {
                    await reimportData()
                }
            }
            Button("Show Stats") {
                printDebugStats()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Songs: \(allSongs.count)\nImported: \(hasImportedInitialData ? "Yes" : "No")")
        }
        #if os(macOS)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Menu {
                    Button("Show Stats") {
                        printDebugStats()
                    }
                    Divider()
                    Button("Re-import Data", role: .destructive) {
                        Task {
                            await reimportData()
                        }
                    }
                    Button("Reset All Data", role: .destructive) {
                        resetAllData()
                    }
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
        #endif
    }
    
    // MARK: - View Components
    
    private var songsListView: some View {
        Group {
            if songs.isEmpty {
                emptyStateView
            } else {
                List(songs) { song in
                    #if os(macOS)
                    SongRowView(song: song)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelect(song)
                        }
                    #else
                    Button(action: { onSelect(song) }) {
                        SongRowView(song: song)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    #endif
                }
                #if os(iOS)
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                #endif
            }
        }
    }
    
    private var albumsListView: some View {
        Group {
            if filteredAlbums.isEmpty {
                emptyStateView
            } else {
                List(filteredAlbums) { album in
                    #if os(macOS)
                    AlbumRowView(album: album)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedAlbum = album
                        }
                    #else
                    Button(action: { selectedAlbum = album }) {
                        AlbumRowView(album: album)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    #endif
                }
                #if os(iOS)
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                #endif
            }
        }
    }
    
    private var artistsListView: some View {
        Group {
            if filteredArtists.isEmpty {
                emptyStateView
            } else {
                List(filteredArtists) { artist in
                    #if os(macOS)
                    ArtistRowView(artist: artist)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedArtist = artist
                        }
                    #else
                    Button(action: { selectedArtist = artist }) {
                        ArtistRowView(artist: artist)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    #endif
                }
                #if os(iOS)
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                #endif
            }
        }
    }
    
    private var singersListView: some View {
        Group {
            if filteredSingers.isEmpty {
                emptyStateView
            } else {
                List(filteredSingers) { singer in
                    #if os(macOS)
                    SingerRowView(singer: singer)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedSinger = singer
                        }
                    #else
                    Button(action: { selectedSinger = singer }) {
                        SingerRowView(singer: singer)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    #endif
                }
                #if os(iOS)
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                #endif
            }
        }
    }
    
    private var coversListView: some View {
        Group {
            if coverSongs.isEmpty {
                emptyStateView
            } else {
                List(coverSongs) { song in
                    #if os(macOS)
                    SongRowView(song: song)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelect(song)
                        }
                    #else
                    Button(action: { onSelect(song) }) {
                        SongRowView(song: song)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    #endif
                }
                #if os(iOS)
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                #endif
            }
        }
    }
    
    private func albumDetailView(for album: Album) -> some View {
        VStack(spacing: 0) {
            // Album Header with Back Button
            HStack {
                Button(action: { selectedAlbum = nil }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Albums")
                    }
                    .foregroundColor(.pink)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            
            // Album songs list
            let albumSongs = album.sortedSongs
            if albumSongs.isEmpty {
                emptyStateView
            } else {
                List(albumSongs) { song in
                    #if os(macOS)
                    SongRowView(song: song)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelect(song)
                        }
                    #else
                    Button(action: { onSelect(song) }) {
                        SongRowView(song: song)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    #endif
                }
                #if os(iOS)
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                #endif
            }
        }
    }
    
    private func artistDetailView(for artist: Artist) -> some View {
        VStack(spacing: 0) {
            // Artist Header with Back Button
            HStack {
                Button(action: { selectedArtist = nil }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Artists")
                    }
                    .foregroundColor(.pink)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            
            // Artist songs list
            let artistSongs = artist.songs?.sorted { $0.name < $1.name } ?? []
            if artistSongs.isEmpty {
                emptyStateView
            } else {
                List(artistSongs) { song in
                    #if os(macOS)
                    SongRowView(song: song)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelect(song)
                        }
                    #else
                    Button(action: { onSelect(song) }) {
                        SongRowView(song: song)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    #endif
                }
                #if os(iOS)
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                #endif
            }
        }
    }
    
    private func singerDetailView(for singer: Singer) -> some View {
        VStack(spacing: 0) {
            // Singer Header with Back Button
            HStack {
                Button(action: { selectedSinger = nil }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Singers")
                    }
                    .foregroundColor(.pink)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            
            // Singer songs list
            let singerSongs = singer.songs?.sorted { $0.name < $1.name } ?? []
            if singerSongs.isEmpty {
                emptyStateView
            } else {
                List(singerSongs) { song in
                    #if os(macOS)
                    SongRowView(song: song)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelect(song)
                        }
                    #else
                    Button(action: { onSelect(song) }) {
                        SongRowView(song: song)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    #endif
                }
                #if os(iOS)
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                #endif
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: emptyStateIcon)
                    .font(.system(size: 64))
                    .foregroundColor(.gray)
                Text(emptyStateMessage)
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }
    
    private var emptyStateIcon: String {
        switch selectedFilter {
        case .allSongs:
            return "doc.text.magnifyingglass"
        case .byAlbum:
            return "opticaldisc"
        case .byArtist:
            return "person.circle"
        case .bySinger:
            return "mic.circle"
        case .covers:
            return "music.note.list"
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedFilter {
        case .allSongs:
            return "No songs found"
        case .byAlbum:
            return "No albums found"
        case .byArtist:
            return "No artists found"
        case .bySinger:
            return "No singers found"
        case .covers:
            return "No covers found"
        }
    }
    
    private func resetAllData() {
        print("🗑️ Deleting all data and resetting import flag...")
        
        // Delete all data
        let manager = SongDataManager(modelContext: modelContext)
        manager.deleteAllData()
        
        // Reset the flag
        hasImportedInitialData = false
        
        print("✅ Reset complete. App will re-import on next launch.")
    }
    
    private func reimportData() async {
        do {
            print("📥 Re-importing data from songs.json...")
            
            let container = modelContext.container
            let backgroundContext = ModelContext(container)
            
            let importService = DataImportService()
            try await importService.importEnhancedJSON(from: "songs", into: backgroundContext)
            
            try backgroundContext.save()
            
            print("✅ Successfully re-imported songs")
        } catch {
            print("❌ Failed to re-import data: \(error)")
        }
    }
    
    private func printDebugStats() {
        let manager = SongDataManager(modelContext: modelContext)
        print("""
        
        📊 Debug Stats:
        ===============
        Songs: \(manager.getSongCount())
        Artists: \(manager.getArtistCount())
        Albums: \(manager.getAlbumCount())
        Singers: \(singers.count)
        Has Imported: \(hasImportedInitialData)
        ===============
        
        """)
    }
}

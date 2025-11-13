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
            searchHeaderView
            contentView
        }
        .alert("Debug Menu", isPresented: $showingDebugMenu) {
            Button("Reset All Data", role: .destructive) {
                Task {
                    await resetAllData()
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
                    Button("Reset All Data", role: .destructive) {
                        Task {
                            await resetAllData()
                        }
                    }
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
        #endif
    }
    
    // MARK: - Header Views
    
    @ViewBuilder
    private var searchHeaderView: some View {
        #if os(macOS)
        macOSSearchHeader
        #elseif os(tvOS)
        tvOSSearchHeader
        #else
        iOSSearchHeader
        #endif
    }
    
    private var macOSSearchHeader: some View {
        VStack(spacing: 0) {
            searchBarView
            filterPickerView
        }
    }
    
    private var tvOSSearchHeader: some View {
        VStack(spacing: 0) {
            searchBarView
            filterPickerView
        }
    }
    
    private var iOSSearchHeader: some View {
        VStack(spacing: 0) {
            // Title with Debug Button
            HStack {
                Text("Dead Sheets")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: { showingDebugMenu = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 10)
            
            searchBarView
            filterPickerView
        }
    }
    
    // MARK: - Search Bar & Filter Components
    
    private var searchBarView: some View {
        Group {
            #if os(macOS)
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
            #elseif os(tvOS)
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.title2)
                TextField("Search songs...", text: $searchText)
                    .font(.title3)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 15)
            .background(Color.white.opacity(0.1))
            #else
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
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.bottom, 8)
            #endif
        }
    }
    
    private var filterPickerView: some View {
        Group {
            #if os(iOS)
            // iOS uses custom pill buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SearchFilter.allCases, id: \.self) { filter in
                        Button(action: { selectFilter(filter) }) {
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
            #elseif os(tvOS)
            // tvOS uses segmented picker with custom spacing
            Picker("Filter", selection: $selectedFilter) {
                ForEach(SearchFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 40)
            .padding(.top, 15)
            .padding(.bottom, 20)
            .onChange(of: selectedFilter) { _, _ in
                resetSelections()
            }
            #else
            // macOS uses standard segmented picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(SearchFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedFilter) { _, _ in
                resetSelections()
            }
            #endif
        }
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        switch selectedFilter {
        case .allSongs:
            songsListView
        case .byAlbum:
            if let selectedAlbum {
                DetailView(
                    backButtonTitle: "Albums",
                    songs: selectedAlbum.sortedSongs,
                    onBack: { self.selectedAlbum = nil },
                    onSelect: onSelect
                )
            } else {
                albumsListView
            }
        case .byArtist:
            if let selectedArtist {
                DetailView(
                    backButtonTitle: "Artists",
                    songs: selectedArtist.songs?.sorted { $0.name < $1.name } ?? [],
                    onBack: { self.selectedArtist = nil },
                    onSelect: onSelect
                )
            } else {
                artistsListView
            }
        case .bySinger:
            if let selectedSinger {
                DetailView(
                    backButtonTitle: "Singers",
                    songs: selectedSinger.songs?.sorted { $0.name < $1.name } ?? [],
                    onBack: { self.selectedSinger = nil },
                    onSelect: onSelect
                )
            } else {
                singersListView
            }
        case .covers:
            coversListView
        }
    }
    
    // MARK: - Helper Methods
    
    private func selectFilter(_ filter: SearchFilter) {
        selectedFilter = filter
        resetSelections()
    }
    
    private func resetSelections() {
        selectedAlbum = nil
        selectedArtist = nil
        selectedSinger = nil
    }
    
    // MARK: - View Components

    private var songsListView: some View {
        SongsListView(songs: songs, onSelect: onSelect)
    }

    private var albumsListView: some View {
        AlbumsListView(albums: filteredAlbums) { album in
            selectedAlbum = album
        }
    }

    private var artistsListView: some View {
        ArtistsListView(artists: filteredArtists) { artist in
            selectedArtist = artist
        }
    }

    private var singersListView: some View {
        SingersListView(singers: filteredSingers) { singer in
            selectedSinger = singer
        }
    }

    private var coversListView: some View {
        CoversListView(songs: coverSongs, onSelect: onSelect)
    }
    
    // Reusable Detail View for Album/Artist/Singer
    private struct DetailView: View {
        let backButtonTitle: String
        let songs: [Song]
        let onBack: () -> Void
        let onSelect: (Song) -> Void
        
        var body: some View {
            VStack(spacing: 0) {
                // Back Button Header
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text(backButtonTitle)
                        }
                        .foregroundColor(.pink)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 12)

                // Songs list
                PlatformListView(
                    items: songs,
                    emptyContent: {
                        EmptyStateView(filter: .allSongs)
                    },
                    rowContent: { song in
                        SongRowView(song: song)
                    },
                    onSelect: onSelect
                )
            }
        }
    }

    @MainActor
    private func resetAllData() async {
        print("🗑️ Deleting all data and resetting import flag...")
        
        // Delete all data
        let manager = SongDataManager(modelContext: modelContext)
        manager.deleteAllData()
        
        // Reset the flag
        hasImportedInitialData = false
        
        await reimportData()
    }
    
    @MainActor
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

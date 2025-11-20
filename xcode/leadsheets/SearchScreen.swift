import SwiftUI
import SwiftData

enum SearchFilter: String, CaseIterable {
    case allSongs = "All Songs"
    case byAlbum = "By Album"
    case byArtist = "By Artist"
    case bySinger = "By Singer"
    case byWriter = "By Writer"
    case covers = "Covers"
}

// Wrapper for grouped writers with combined contributions
struct GroupedWriter: Identifiable {
    let id = UUID()
    let name: String
    let contributions: [String] // e.g., ["music", "lyrics"]
    let songs: [Song]
    let imageFileName: String?
    
    var displayContribution: String {
        contributions
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .sorted()
            .joined(separator: " & ")
    }
}

struct SearchScreen: View {
    @Binding var searchText: String
    let songs: [Song]
    let onSelect: (Song) -> Void
    
    @State private var selectedFilter: SearchFilter = .allSongs
    @State private var selectedAlbum: Album?
    @State private var selectedArtist: Artist?
    @State private var selectedSinger: Singer?
    @State private var selectedGroupedWriter: GroupedWriter?
    @Environment(\.modelContext) private var modelContext
    @Query private var albums: [Album]
    @Query private var artists: [Artist]
    @Query private var singers: [Singer]
    @Query private var writers: [Writer]
    @Query(sort: \Song.name) private var allSongs: [Song]

    @State private var debugManager: DebugMenuManager?
    @FocusState private var isSearchFieldFocused: Bool
    
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
    
    // Filtered writers based on search - now returns GroupedWriter
    private var filteredGroupedWriters: [GroupedWriter] {
        let baseWriters = searchText.isEmpty ? writers : writers.filter { writer in
            writer.name.localizedCaseInsensitiveContains(searchText) ||
            writer.contribution.localizedCaseInsensitiveContains(searchText)
        }
        
        // Group writers by name
        let groupedByName = Dictionary(grouping: baseWriters) { $0.name }
        
        var groupedWriters: [GroupedWriter] = []
        
        for (name, writersWithSameName) in groupedByName {
            // Get all songs from all contributions for this writer
            let allSongsSet = Set(writersWithSameName.flatMap { $0.songs ?? [] })
            
            // Check if all writer instances have the exact same songs
            let allHaveSameSongs = writersWithSameName.allSatisfy { writer in
                Set(writer.songs ?? []) == allSongsSet
            }
            
            if allHaveSameSongs && writersWithSameName.count > 1 {
                // Combine contributions for this writer
                let contributions = writersWithSameName.map { $0.contribution }
                let songs = Array(allSongsSet).sorted { $0.name < $1.name }
                
                groupedWriters.append(GroupedWriter(
                    name: name,
                    contributions: contributions,
                    songs: songs,
                    imageFileName: writersWithSameName.first?.imageFileName,
                ))
            } else {
                // Keep separate entries for different song sets
                for writer in writersWithSameName {
                    groupedWriters.append(GroupedWriter(
                        name: writer.name,
                        contributions: [writer.contribution],
                        songs: (writer.songs ?? []).sorted { $0.name < $1.name },
                        imageFileName: writer.imageFileName,
                    ))
                }
            }
        }
        
        return groupedWriters.sorted { $0.name < $1.name }
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
        .onAppear {
            if debugManager == nil {
                debugManager = DebugMenuManager(modelContext: modelContext)
            }
        }
        .modifier(OptionalDebugMenuModifier(manager: debugManager))
    }
    
    // MARK: - Header View
    
    @ViewBuilder
    private var searchHeaderView: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            // Title with Debug Button
            HStack {
                Text("Dead Sheets")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: { debugManager?.showingDebugMenu = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 10)
            #endif
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
                Spacer()
                Image(systemName: "magnifyingglass")
                    .foregroundColor(isSearchFieldFocused ? .pink : .gray)
                TextField("Search songs...", text: $searchText)
                    .focused($isSearchFieldFocused)
                    .frame(minHeight: 56)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSearchFieldFocused ? .pink : .gray.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .gray.opacity(0.2), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 30)
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
            // macOS uses a two-row grid for better spacing
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ForEach([SearchFilter.allSongs, .byAlbum, .byArtist], id: \.self) { filter in
                        filterButton(for: filter)
                    }
                }
                HStack(spacing: 12) {
                    ForEach([SearchFilter.bySinger, .byWriter, .covers], id: \.self) { filter in
                        filterButton(for: filter)
                    }
                }
                
                Divider()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            #endif
        }
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        switch selectedFilter {
        case .allSongs:
            SongsListView(songs: songs, onSelect: onSelect)
        case .byAlbum:
            if let selectedAlbum {
                DetailView(
                    backButtonTitle: "Albums",
                    songs: selectedAlbum.sortedSongs,
                    onBack: { self.selectedAlbum = nil },
                    onSelect: onSelect
                )
            } else {
                AlbumsListView(albums: filteredAlbums) { album in
                    selectedAlbum = album
                }
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
                ArtistsListView(artists: filteredArtists) { artist in
                    selectedArtist = artist
                }
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
                SingersListView(singers: filteredSingers) { singer in
                    selectedSinger = singer
                }
            }
        case .byWriter:
            if let selectedGroupedWriter {
                DetailView(
                    backButtonTitle: "Writers",
                    songs: selectedGroupedWriter.songs,
                    onBack: { self.selectedGroupedWriter = nil },
                    onSelect: onSelect
                )
            } else {
                GroupedWritersListView(groupedWriters: filteredGroupedWriters) { groupedWriter in
                    selectedGroupedWriter = groupedWriter
                }
            }
        case .covers:
            CoversListView(songs: coverSongs, onSelect: onSelect)
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
        selectedGroupedWriter = nil
    }
    
    #if os(macOS)
    private func filterButton(for filter: SearchFilter) -> some View {
        Button(action: { selectFilter(filter) }) {
            Text(filter.rawValue)
                .font(.body)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selectedFilter == filter ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                .foregroundColor(selectedFilter == filter ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
    #endif
    

    // MARK: - Detail View

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
}

// MARK: - Helper Modifier

private struct OptionalDebugMenuModifier: ViewModifier {
    let manager: DebugMenuManager?

    func body(content: Content) -> some View {
        if let manager = manager {
            content.debugMenu(manager: manager)
        } else {
            content
        }
    }
}

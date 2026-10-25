import DeadSheetsKit
import SwiftUI

enum SearchFilter: String, CaseIterable {
    case allSongs = "All Songs"
    case byAlbum = "By Album"
    case byArtist = "By Artist"
    case bySinger = "By Singer"
    case byWriter = "By Writer"
    case covers = "Covers"
}

struct SearchScreen: View {
    @Binding var searchText: String
    let onSelect: (Song) -> Void
    var selectedSong: Song? = nil

    @Environment(\.catalog) private var catalog
    @State private var selectedFilter: SearchFilter = .allSongs
    @State private var selectedAlbum: Album?
    @State private var selectedArtist: Artist?
    @State private var selectedSinger: Person?
    @State private var selectedWriterGroup: WriterGroup?
    @State private var showSettings = false

    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            searchHeaderView
            contentView
        }
    }
    
    // MARK: - Header View

    @ViewBuilder
    private var searchHeaderView: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            HStack {
                Text("Dead Sheets")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape")
                        .font(.title2)
                        .foregroundColor(.pink)
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 10)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
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
            .background(Color(.secondarySystemGroupedBackground))
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
            SongsListView(songs: catalog.songs(matching: searchText), onSelect: onSelect, selectedSong: selectedSong)
        case .byAlbum:
            if let selectedAlbum {
                DetailView(
                    backButtonTitle: "Albums",
                    songs: catalog.songs(on: selectedAlbum),
                    onBack: { self.selectedAlbum = nil },
                    onSelect: onSelect,
                    selectedSong: selectedSong
                )
            } else {
                AlbumsListView(albums: catalog.albums(matching: searchText)) { album in
                    selectedAlbum = album
                }
            }
        case .byArtist:
            if let selectedArtist {
                DetailView(
                    backButtonTitle: "Artists",
                    songs: catalog.songs(by: selectedArtist),
                    onBack: { self.selectedArtist = nil },
                    onSelect: onSelect,
                    selectedSong: selectedSong
                )
            } else {
                ArtistsListView(artists: catalog.artists(matching: searchText)) { artist in
                    selectedArtist = artist
                }
            }
        case .bySinger:
            if let selectedSinger {
                DetailView(
                    backButtonTitle: "Singers",
                    songs: catalog.songs(sungBy: selectedSinger),
                    onBack: { self.selectedSinger = nil },
                    onSelect: onSelect,
                    selectedSong: selectedSong
                )
            } else {
                SingersListView(singers: catalog.singers(matching: searchText)) { singer in
                    selectedSinger = singer
                }
            }
        case .byWriter:
            if let selectedWriterGroup {
                DetailView(
                    backButtonTitle: "Writers",
                    songs: selectedWriterGroup.songs,
                    onBack: { self.selectedWriterGroup = nil },
                    onSelect: onSelect,
                    selectedSong: selectedSong
                )
            } else {
                WriterGroupsListView(groups: catalog.writerGroups(matching: searchText)) { group in
                    selectedWriterGroup = group
                }
            }
        case .covers:
            CoversListView(songs: catalog.covers(matching: searchText), onSelect: onSelect, selectedSong: selectedSong)
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
        selectedWriterGroup = nil
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
        var selectedSong: Song? = nil

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
                        SongRowView(song: song, isSelected: selectedSong?.id == song.id)
                    },
                    onSelect: onSelect
                )
            }
        }
    }
}

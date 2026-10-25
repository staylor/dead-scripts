#if os(iOS) || os(macOS)
import DeadSheetsKit
import SwiftData
import SwiftUI

/// The library and the selected lead sheet. On iPhone the split view collapses into a stack.
struct SplitRootView: View {
    @Environment(\.catalog) private var catalog
    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [Favorite]
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    @SceneStorage("category") private var category: LibraryCategory = .songs
    @SceneStorage("songFilter") private var songFilter: SongFilter = .all
    @State private var path: [LibraryRoute] = []
    @State private var searchText = ""
    @SceneStorage("selectedSongID") private var selectedSongID: Song.ID?
    @State private var compactColumn: NavigationSplitViewColumn = .sidebar
    #if os(iOS)
    @State private var showsSettings = false
    #endif

    private let cloudSync = CloudSyncManager.shared
    #if os(iOS)
    private let watchConnectivity = WatchConnectivityManager.shared
    #endif

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $compactColumn) {
            NavigationStack(path: $path) {
                LibraryList(category: category, searchText: searchText, songFilter: songFilter, selection: songSelection)
                    .navigationTitle(category == .songs ? songFilter.title : category.title)
                    .navigationDestination(for: LibraryRoute.self) { route in
                        if case .setlist(let setlistID) = route {
                            SetlistView(setlistID: setlistID, selection: songSelection)
                        } else {
                            LibraryRouteView(route: route, selection: songSelection)
                        }
                    }
                    .searchable(text: $searchText, placement: searchPlacement, prompt: "Titles, albums, lyrics")
                    .safeAreaInset(edge: .top) {
                        CategoryPicker(selection: $category)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }
                    .toolbar {
                        if category == .songs {
                            ToolbarItem {
                                Menu {
                                    Picker("Show", selection: $songFilter) {
                                        ForEach(SongFilter.allCases) { filter in
                                            Label(filter.title, systemImage: filter.systemImage)
                                                .tag(filter)
                                        }
                                    }
                                } label: {
                                    Label("Filter", systemImage: "line.3.horizontal.decrease")
                                        .symbolVariant(songFilter == .all ? .none : .circle.fill)
                                }
                            }
                        }
                        #if os(iOS)
                        ToolbarItem(placement: .primaryAction) {
                            Button("Settings", systemImage: "gearshape") {
                                showsSettings = true
                            }
                        }
                        #endif
                    }
            }
            .navigationSplitViewColumnWidth(min: 360, ideal: 400, max: 480)
        } detail: {
            if let song = selectedSongID.flatMap(catalog.song(id:)) {
                SheetView(song: song, navigation: navigation(from: song))
                    .id(song.id)
            } else {
                ContentUnavailableView(
                    "Select a Song",
                    systemImage: "music.note",
                    description: Text("Choose a song to see its lead sheet.")
                )
            }
        }
        #if os(macOS)
        .navigationSplitViewStyle(.balanced)
        #else
        .sheet(isPresented: $showsSettings) {
            SettingsView()
        }
        #endif
        .playbackAlerts()
        .onChange(of: category) {
            path = []
        }
        .onAppear {
            if selectedSongID != nil {
                compactColumn = .detail
            }
        }
        #if os(iOS)
        .onChange(of: compactColumn) { _, column in
            // Going back to the library on iPhone closes the song, so a relaunch doesn't reopen it.
            if column == .sidebar, horizontalSizeClass == .compact {
                selectedSongID = nil
            }
        }
        #endif
        .onChange(of: cloudSync.selectedSongSlug) { _, slug in
            if let slug {
                show(slug)
            }
        }
        #if os(iOS)
        .onChange(of: watchConnectivity.selectedSongID) { _, songID in
            guard UIDevice.current.userInterfaceIdiom == .phone, let songID, show(songID) else { return }
            // Forward the watch's selection so an iPad following along sees it too.
            cloudSync.sendSelection(slug: songID)
        }
        #endif
    }

    /// The selection as the library sets it, which also tells other devices.
    private var songSelection: Binding<Song.ID?> {
        Binding(
            get: { selectedSongID },
            set: { songID in
                guard let songID else { return }
                selectedSongID = songID
                compactColumn = .detail
                #if os(iOS)
                watchConnectivity.sendSelectedSong(id: songID)
                #endif
                cloudSync.sendSelection(slug: songID)
            }
        )
    }

    /// The songs of the list the open song was chosen from, in the order shown.
    private var openedFromSongs: [Song] {
        if case .setlist(let setlistID)? = path.last {
            let setlist = modelContext.model(for: setlistID) as? Setlist
            return (setlist?.songIDs ?? []).compactMap(catalog.song(id:))
        }
        if let route = path.last {
            return route.songs(in: catalog)
        }
        switch category {
        case .songs: return catalog.songs(matching: searchText, filter: songFilter, favoriteIDs: Set(favorites.map(\.songID)))
        case .covers: return catalog.covers(matching: searchText)
        case .albums, .artists, .singers, .writers, .setlists: return []
        }
    }

    private func navigation(from song: Song) -> SongNavigation {
        let songs = openedFromSongs
        guard let index = songs.firstIndex(where: { $0.id == song.id }) else {
            return SongNavigation(previous: nil, next: nil)
        }
        let selection = songSelection
        func select(_ offset: Int) -> (() -> Void)? {
            songs.indices.contains(index + offset) ? { selection.wrappedValue = songs[index + offset].id } : nil
        }
        return SongNavigation(previous: select(-1), next: select(1))
    }

    /// Shows a song selected on another device. Returns whether the selection changed.
    @discardableResult
    private func show(_ songID: Song.ID) -> Bool {
        guard songID != selectedSongID, catalog.song(id: songID) != nil else { return false }
        selectedSongID = songID
        compactColumn = .detail
        return true
    }

    private var searchPlacement: SearchFieldPlacement {
        #if os(macOS)
        .sidebar
        #else
        horizontalSizeClass == .regular ? .navigationBarDrawer(displayMode: .always) : .automatic
        #endif
    }
}
#endif

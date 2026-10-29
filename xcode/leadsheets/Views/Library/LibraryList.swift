import DeadSheetsKit
import SwiftData
import SwiftUI

/// The root list of the library for one category.
struct LibraryList: View {
    let category: LibraryCategory
    let searchText: String
    var songFilter: SongFilter = .all
    @Binding var selection: Song.ID?

    @Environment(\.catalog) private var catalog
    #if os(iOS) || os(macOS)
    @Query private var favorites: [Favorite]
    #endif

    var body: some View {
        switch category {
        case .songs:
            let songs = catalog.songs(matching: searchText, filter: songFilter, favoriteIDs: favoriteIDs)
            SongList(songs: songs, selection: $selection)
                .overlay {
                    if songs.isEmpty {
                        if !searchText.isEmpty {
                            ContentUnavailableView.search(text: searchText)
                        } else if songFilter == .favorites {
                            ContentUnavailableView(
                                "No Favorites",
                                systemImage: "heart",
                                description: Text("Tap the heart on a lead sheet to add it here.")
                            )
                        } else {
                            ContentUnavailableView("No \(songFilter.title)", systemImage: songFilter.systemImage)
                        }
                    }
                }
        case .covers:
            let covers = catalog.covers(matching: searchText)
            SongList(songs: covers, selection: $selection)
                .emptyState(isEmpty: covers.isEmpty, category: category, searchText: searchText)
        case .albums:
            routeList(catalog.albums(matching: searchText).map(LibraryRoute.album))
        case .artists:
            routeList(catalog.artists(matching: searchText).map(LibraryRoute.artist))
        case .singers:
            routeList(catalog.singers(matching: searchText).map(LibraryRoute.singer))
        case .writers:
            routeList(catalog.writerGroups(matching: searchText).map(LibraryRoute.writers))
        case .setlists:
            #if os(iOS) || os(macOS)
            SetlistsList()
            #else
            EmptyView()
            #endif
        }
    }

    private func routeList(_ routes: [LibraryRoute]) -> some View {
        List(routes) { route in
            NavigationLink(value: route) {
                RouteRow(route: route)
            }
        }
        .emptyState(isEmpty: routes.isEmpty, category: category, searchText: searchText)
    }

    private var favoriteIDs: Set<Song.ID> {
        #if os(iOS) || os(macOS)
        Set(favorites.map(\.songID))
        #else
        []
        #endif
    }
}

extension Catalog {
    func songs(matching query: String, filter: SongFilter, favoriteIDs: Set<Song.ID>) -> [Song] {
        switch filter {
        case .all: songs(matching: query)
        case .covers: covers(matching: query)
        case .favorites: songs(matching: query).filter { favoriteIDs.contains($0.id) }
        }
    }
}

/// The songs on an album, by an artist, sung by someone or written by someone.
struct LibraryRouteView: View {
    let route: LibraryRoute
    @Binding var selection: Song.ID?

    @Environment(\.catalog) private var catalog

    var body: some View {
        SongList(songs: route.songs(in: catalog), selection: $selection)
            .navigationTitle(route.title)
    }
}

/// On iOS and macOS, choosing a song selects it and the split view shows it; on tvOS the row pushes it.
struct SongList: View {
    let songs: [Song]
    @Binding var selection: Song.ID?

    var body: some View {
        #if os(tvOS)
        List(songs) { song in
            NavigationLink(value: song) {
                SongRow(song: song)
            }
        }
        #else
        List(songs, selection: $selection) { song in
            SongRow(song: song)
        }
        .contextMenu(forSelectionType: Song.ID.self) { songIDs in
            if let song = songs.first(where: { songIDs.contains($0.id) }), let appleMusicID = song.appleMusicID {
                Button("Play in Apple Music", systemImage: "play.fill") {
                    Task {
                        await MusicPlayerService.shared.play(appleMusicID: appleMusicID, title: song.title)
                    }
                }
            }
        }
        #endif
    }
}

struct CategoryPicker: View {
    @Binding var selection: LibraryCategory

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let picker = Picker("Browse", selection: $selection) {
            ForEach(LibraryCategory.browsable) { category in
                Label(category.title, systemImage: category.systemImage)
                    .tag(category)
            }
        }
        .labelsHidden()

        // Six segments truncate at accessibility text sizes.
        if dynamicTypeSize.isAccessibilitySize {
            picker
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            picker
                .pickerStyle(.segmented)
                .labelStyle(.titleOnly)
        }
    }
}

extension View {
    fileprivate func emptyState(isEmpty: Bool, category: LibraryCategory, searchText: String) -> some View {
        overlay {
            if isEmpty {
                if searchText.isEmpty {
                    ContentUnavailableView("No \(category.title)", systemImage: category.systemImage)
                } else {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
    }
}

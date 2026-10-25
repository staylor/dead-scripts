import DeadSheetsKit
import SwiftUI

/// The root list of the library for one category.
struct LibraryList: View {
    let category: LibraryCategory
    let searchText: String
    @Binding var selection: Song.ID?

    @Environment(\.catalog) private var catalog

    var body: some View {
        switch category {
        case .songs:
            let songs = catalog.songs(matching: searchText)
            SongList(songs: songs, selection: $selection)
                .emptyState(isEmpty: songs.isEmpty, category: category, searchText: searchText)
        case .covers:
            let covers = catalog.covers(matching: searchText)
            SongList(songs: covers, selection: $selection)
                .emptyState(isEmpty: covers.isEmpty, category: category, searchText: searchText)
        case .albums:
            let albums = catalog.albums(matching: searchText)
            List(albums) { album in
                NavigationLink(value: LibraryRoute.album(album)) {
                    AlbumRow(album: album)
                }
            }
            .emptyState(isEmpty: albums.isEmpty, category: category, searchText: searchText)
        case .artists:
            let artists = catalog.artists(matching: searchText)
            List(artists) { artist in
                NavigationLink(value: LibraryRoute.artist(artist)) {
                    ArtistRow(artist: artist)
                }
            }
            .emptyState(isEmpty: artists.isEmpty, category: category, searchText: searchText)
        case .singers:
            let singers = catalog.singers(matching: searchText)
            List(singers) { singer in
                NavigationLink(value: LibraryRoute.singer(singer)) {
                    SingerRow(singer: singer)
                }
            }
            .emptyState(isEmpty: singers.isEmpty, category: category, searchText: searchText)
        case .writers:
            let groups = catalog.writerGroups(matching: searchText)
            List(groups) { group in
                NavigationLink(value: LibraryRoute.writers(group)) {
                    WriterGroupRow(group: group)
                }
            }
            .emptyState(isEmpty: groups.isEmpty, category: category, searchText: searchText)
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
        #endif
    }
}

struct CategoryPicker: View {
    @Binding var selection: LibraryCategory

    var body: some View {
        Picker("Browse", selection: $selection) {
            ForEach(LibraryCategory.allCases) { category in
                Text(category.title)
                    .tag(category)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }
}

private extension View {
    func emptyState(isEmpty: Bool, category: LibraryCategory, searchText: String) -> some View {
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

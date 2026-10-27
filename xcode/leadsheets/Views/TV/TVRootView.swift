#if os(tvOS)
import DeadSheetsKit
import SwiftUI

/// A tab per category across the top, as tvOS apps do, plus the system search screen.
struct TVRootView: View {
    var body: some View {
        TabView {
            ForEach(LibraryCategory.browsable) { category in
                Tab(category.title, systemImage: category.systemImage) {
                    TVLibraryTab(category: category)
                }
            }
            Tab("Search", systemImage: "magnifyingglass", role: .search) {
                TVSearchTab()
            }
        }
    }
}

private struct TVLibraryTab: View {
    let category: LibraryCategory

    var body: some View {
        NavigationStack {
            LibraryList(category: category, searchText: "", selection: .constant(nil))
                .navigationDestination(for: LibraryRoute.self) { route in
                    LibraryRouteView(route: route, selection: .constant(nil))
                }
                .navigationDestination(for: Song.self) { song in
                    TVSheetScreen(song: song)
                }
        }
    }
}

private struct TVSearchTab: View {
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            LibraryList(category: .songs, searchText: searchText, selection: .constant(nil))
                .searchable(text: $searchText, prompt: "Titles, albums, lyrics")
                .navigationDestination(for: Song.self) { song in
                    TVSheetScreen(song: song)
                }
        }
    }
}
#endif

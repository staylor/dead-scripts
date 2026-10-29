#if os(iOS) || os(macOS)
import DeadSheetsKit
import SwiftData
import SwiftUI

struct SetlistsList: View {
    let searchText: String

    @Environment(\.modelContext) private var context
    @Query(sort: \Setlist.createdAt, order: .reverse) private var setlists: [Setlist]
    @State private var isNaming = false
    @State private var saveFailure: UserData.SaveFailure?

    private var matchingSetlists: [Setlist] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty ? setlists : setlists.filter { $0.name.localizedStandardContains(query) }
    }

    var body: some View {
        let matches = matchingSetlists
        List {
            ForEach(matches) { setlist in
                NavigationLink(value: LibraryRoute.setlist(setlist.id)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(setlist.name)
                        Text(Counts.songs(setlist.songIDs.count))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
                .accessibilityIdentifier("setlist-\(setlist.name)")
            }
            .onDelete { offsets in
                saveFailure = UserData.shared.save(in: context) {
                    for offset in offsets {
                        context.delete(matches[offset])
                    }
                }
            }
        }
        .overlay {
            if !UserData.shared.isAvailable {
                ContentUnavailableView("Setlists Unavailable", systemImage: "exclamationmark.triangle")
            } else if matches.isEmpty, !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .accessibilityIdentifier("setlist-search-empty")
            } else if setlists.isEmpty {
                ContentUnavailableView {
                    Label("No Setlists", systemImage: LibraryCategory.setlists.systemImage)
                } description: {
                    Text("Put songs in the order you'll play them, then step through them on stage.")
                } actions: {
                    Button("New Setlist") {
                        isNaming = true
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Button("New Setlist", systemImage: "plus") {
                    isNaming = true
                }
                .disabled(!UserData.shared.isAvailable)
            }
        }
        .newSetlistAlert(isPresented: $isNaming)
        .userDataSaveAlert($saveFailure)
    }
}

extension View {
    /// Asks for a name and creates a setlist, optionally starting with a song.
    func newSetlistAlert(isPresented: Binding<Bool>, startingWith songID: Song.ID? = nil) -> some View {
        modifier(NewSetlistAlert(isPresented: isPresented, songID: songID))
    }
}

private struct NewSetlistAlert: ViewModifier {
    @Binding var isPresented: Bool
    let songID: Song.ID?

    @Environment(\.modelContext) private var context
    @State private var name = ""
    @State private var saveFailure: UserData.SaveFailure?

    func body(content: Content) -> some View {
        content.alert("New Setlist", isPresented: $isPresented) {
            TextField("Name", text: $name)
            Button("Create") {
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                saveFailure = UserData.shared.save(in: context) {
                    context.insert(Setlist(name: trimmed.isEmpty ? "Untitled Setlist" : trimmed, songIDs: songID.map { [$0] } ?? []))
                }
                if saveFailure == nil {
                    name = ""
                }
            }
            Button("Cancel", role: .cancel) {
                name = ""
            }
        }
        .userDataSaveAlert($saveFailure)
    }
}
#endif

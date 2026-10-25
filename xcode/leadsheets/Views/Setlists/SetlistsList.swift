#if os(iOS) || os(macOS)
import DeadSheetsKit
import SwiftData
import SwiftUI

struct SetlistsList: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Setlist.createdAt, order: .reverse) private var setlists: [Setlist]
    @State private var isNaming = false

    var body: some View {
        List {
            ForEach(setlists) { setlist in
                NavigationLink(value: LibraryRoute.setlist(setlist.persistentModelID)) {
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
                for offset in offsets {
                    context.delete(setlists[offset])
                }
            }
        }
        .overlay {
            if setlists.isEmpty {
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
            }
        }
        .newSetlistAlert(isPresented: $isNaming)
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

    func body(content: Content) -> some View {
        content.alert("New Setlist", isPresented: $isPresented) {
            TextField("Name", text: $name)
            Button("Create") {
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                context.insert(Setlist(name: trimmed.isEmpty ? "Untitled Setlist" : trimmed, songIDs: songID.map { [$0] } ?? []))
                name = ""
            }
            Button("Cancel", role: .cancel) {
                name = ""
            }
        }
    }
}
#endif

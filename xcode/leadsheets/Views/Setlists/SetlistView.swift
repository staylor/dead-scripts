#if os(iOS) || os(macOS)
import DeadSheetsKit
import SwiftData
import SwiftUI

/// A setlist's songs in playing order. Opening one steps through the rest with Previous and Next.
struct SetlistView: View {
    @Binding var selection: Song.ID?

    @Environment(\.catalog) private var catalog
    @Environment(\.modelContext) private var context
    @Query private var setlists: [Setlist]
    @State private var isAddingSongs = false
    @State private var saveFailure: UserData.SaveFailure?

    init(setlistID: Setlist.ID, selection: Binding<Song.ID?>) {
        _selection = selection
        _setlists = Query(filter: #Predicate<Setlist> { $0.id == setlistID })
    }

    var body: some View {
        if let setlist = setlists.first {
            content(for: setlist)
        } else {
            ContentUnavailableView("Setlist Deleted", systemImage: LibraryCategory.setlists.systemImage)
        }
    }

    private func content(for setlist: Setlist) -> some View {
        // Songs removed from the catalog drop out, and reordering or deleting tidies them away.
        let songs = setlist.songIDs.compactMap(catalog.song(id:))

        return List(selection: $selection) {
            ForEach(songs) { song in
                SongRow(song: song)
            }
            .onMove { offsets, destination in
                var reordered = songs
                reordered.move(fromOffsets: offsets, toOffset: destination)
                saveFailure = UserData.shared.save(in: context, restoring: [setlist]) {
                    setlist.songIDs = reordered.map(\.id)
                }
            }
            .onDelete { offsets in
                let removed = Set(offsets.map { songs[$0].id })
                saveFailure = UserData.shared.save(in: context, restoring: [setlist]) {
                    setlist.songIDs = songs.map(\.id).filter { !removed.contains($0) }
                }
            }
        }
        .overlay {
            if songs.isEmpty {
                ContentUnavailableView {
                    Label("No Songs", systemImage: "music.note.list")
                } actions: {
                    Button("Add Songs") {
                        isAddingSongs = true
                    }
                }
            }
        }
        .navigationTitle(setlist.name)
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
            #endif
            ToolbarItem {
                Button("Add Songs", systemImage: "plus") {
                    isAddingSongs = true
                }
            }
        }
        .sheet(isPresented: $isAddingSongs) {
            SongPicker(setlist: setlist)
        }
        .userDataSaveAlert($saveFailure)
    }
}

/// Adds and removes songs from a setlist; new songs go at the end.
private struct SongPicker: View {
    let setlist: Setlist

    @Environment(\.dismiss) private var dismiss
    @Environment(\.catalog) private var catalog
    @Environment(\.modelContext) private var context
    @State private var searchText = ""
    @State private var saveFailure: UserData.SaveFailure?

    var body: some View {
        NavigationStack {
            List(catalog.songs(matching: searchText)) { song in
                let isAdded = setlist.songIDs.contains(song.id)
                Button {
                    saveFailure = UserData.shared.save(in: context, restoring: [setlist]) {
                        if setlist.songIDs.contains(song.id) {
                            setlist.songIDs.removeAll { $0 == song.id }
                        } else {
                            setlist.songIDs.append(song.id)
                        }
                    }
                } label: {
                    HStack {
                        SongRow(song: song)
                        Spacer()
                        Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle")
                            .foregroundStyle(.tint)
                            .imageScale(.large)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isAdded ? .isSelected : [])
            }
            .searchable(text: $searchText, prompt: "Titles, albums, lyrics")
            .navigationTitle("Add Songs")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        dismiss()
                    }
                }
            }
        }
        .userDataSaveAlert($saveFailure)
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 520)
        #endif
    }
}
#endif

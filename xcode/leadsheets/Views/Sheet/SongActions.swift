#if os(iOS) || os(macOS)
import DeadSheetsKit
import SwiftData
import SwiftUI

struct FavoriteButton: View {
    let songID: Song.ID

    @Environment(\.modelContext) private var context
    @Query private var favorites: [Favorite]
    @State private var saveFailure: UserData.SaveFailure?

    init(songID: Song.ID) {
        self.songID = songID
        _favorites = Query(filter: #Predicate<Favorite> { $0.songID == songID })
    }

    var body: some View {
        let isFavorite = !favorites.isEmpty
        Button(isFavorite ? "Remove from Favorites" : "Add to Favorites", systemImage: isFavorite ? "heart.fill" : "heart") {
            saveFailure = UserData.shared.save(in: context) {
                if isFavorite {
                    favorites.forEach(context.delete)
                } else {
                    context.insert(Favorite(songID: songID))
                }
            }
        }
        .disabled(!UserData.shared.isAvailable)
        .userDataSaveAlert($saveFailure)
    }
}

struct AddToSetlistMenu: View {
    let songID: Song.ID

    @Environment(\.modelContext) private var context
    @Query(sort: \Setlist.createdAt, order: .reverse) private var setlists: [Setlist]
    @State private var isNaming = false
    @State private var saveFailure: UserData.SaveFailure?

    var body: some View {
        Menu("Add to Setlist", systemImage: "text.badge.plus") {
            ForEach(setlists) { setlist in
                let contains = setlist.songIDs.contains(songID)
                Button {
                    saveFailure = UserData.shared.save(in: context, restoring: [setlist]) {
                        if !setlist.songIDs.contains(songID) {
                            setlist.songIDs.append(songID)
                        }
                    }
                } label: {
                    if contains {
                        Label(setlist.name, systemImage: "checkmark")
                    } else {
                        Text(setlist.name)
                    }
                }
                .disabled(contains)
            }
            if !setlists.isEmpty {
                Divider()
            }
            Button("New Setlist…", systemImage: "plus") {
                isNaming = true
            }
        }
        .disabled(!UserData.shared.isAvailable)
        .newSetlistAlert(isPresented: $isNaming, startingWith: songID)
        .userDataSaveAlert($saveFailure)
    }
}
#endif

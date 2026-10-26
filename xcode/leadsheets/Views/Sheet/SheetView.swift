#if os(iOS) || os(macOS)
import DeadSheetsKit
import SwiftUI

/// A song's lead sheet, with playback and its lyrics in an inspector.
struct SheetView: View {
    let song: Song
    var navigation = SongNavigation(previous: nil, next: nil)

    #if os(macOS)
    @AppStorage("showsLyrics") private var showsLyrics = true
    #else
    @State private var showsLyrics = false
    #endif
    @AppStorage(SettingsKey.keepsScreenOn) private var keepsScreenOn = true

    var body: some View {
        sheet
            .navigationTitle(song.title)
            .navigationSubtitle(subtitle)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #else
            .frame(minWidth: 480)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItemGroup(placement: .bottomBar) {
                    previousButton
                    Spacer()
                    FavoriteButton(songID: song.id)
                    AddToSetlistMenu(songID: song.id)
                    Spacer()
                    nextButton
                }
                #else
                ToolbarItemGroup(placement: .navigation) {
                    previousButton
                    nextButton
                }
                ToolbarItemGroup {
                    FavoriteButton(songID: song.id)
                    AddToSetlistMenu(songID: song.id)
                }
                #endif
                if let appleMusicID = song.appleMusicID {
                    ToolbarItem {
                        PlayButton(appleMusicID: appleMusicID, title: song.title)
                    }
                }
                ToolbarItem {
                    Toggle(isOn: $showsLyrics) {
                        Label("Lyrics", systemImage: "text.quote")
                    }
                }
            }
            .focusedSceneValue(\.shownSong, song)
            .focusedSceneValue(\.showsLyrics, $showsLyrics)
            .focusedSceneValue(\.songNavigation, navigation)
            .pageTurnerKeys(navigation)
            .keepsScreenOn(keepsScreenOn)
            .userActivity(SongActivity.type) { activity in
                activity.title = song.title
                activity.userInfo = [SongActivity.songIDKey: song.id]
                activity.isEligibleForHandoff = true
            }
            .inspector(isPresented: $showsLyrics) {
                LyricsView(song: song)
                    .inspectorColumnWidth(min: 240, ideal: 320, max: 420)
                    .presentationDetents([.medium, .large])
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            }
    }

    private var previousButton: some View {
        Button("Previous Song", systemImage: "chevron.backward") {
            navigation.previous?()
        }
        .disabled(navigation.previous == nil)
    }

    private var nextButton: some View {
        Button("Next Song", systemImage: "chevron.forward") {
            navigation.next?()
        }
        .disabled(navigation.next == nil)
    }

    @ViewBuilder
    private var sheet: some View {
        if let url = song.sheetURL {
            PDFKitView(url: url)
        } else {
            ContentUnavailableView(
                "Lead Sheet Missing",
                systemImage: "doc.questionmark",
                description: Text("“\(song.sheetFileName)” isn’t in this build.")
            )
        }
    }

    private var subtitle: String {
        var subtitle = song.albumTitle
        if let year = song.albumReleaseYear {
            subtitle += " (\(year))"
        }
        #if os(macOS)
        subtitle += " · \(song.creditsText)"
        #endif
        return subtitle
    }
}

#Preview {
    if let song = Catalog.bundled.song(id: "ripple") {
        NavigationStack {
            SheetView(song: song)
        }
    }
}
#endif

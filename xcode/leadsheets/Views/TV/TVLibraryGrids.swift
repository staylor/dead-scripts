#if os(tvOS)
import DeadSheetsKit
import SwiftUI

/// Album covers in rows, as tvOS shows albums.
struct TVAlbumGrid: View {
    @Environment(\.catalog) private var catalog

    var body: some View {
        ScrollView {
            LazyVGrid(columns: Self.columns(5), spacing: 64) {
                ForEach(catalog.albums.map(LibraryRoute.album)) { route in
                    NavigationLink(value: route) {
                        Lockup(title: route.title, subtitle: route.summary(in: catalog)) {
                            TVArtwork(appleMusicID: route.appleMusicID, placeholder: route.placeholder)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                    .buttonStyle(.borderless)
                    .accessibilityIdentifier(route.id)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 40)
        }
    }

    static func columns(_ count: Int) -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 48, alignment: .top), count: count)
    }
}

/// Artists, singers or writers, as round photos.
struct TVPeopleGrid: View {
    let category: LibraryCategory

    @Environment(\.catalog) private var catalog

    var body: some View {
        ScrollView {
            LazyVGrid(columns: TVAlbumGrid.columns(6), spacing: 64) {
                ForEach(routes) { route in
                    NavigationLink(value: route) {
                        PortraitLockup(route: route, summary: route.summary(in: catalog))
                    }
                    .buttonStyle(PortraitButtonStyle())
                    .accessibilityIdentifier(route.id)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 40)
        }
    }

    private var routes: [LibraryRoute] {
        switch category {
        case .artists: catalog.artists.map(LibraryRoute.artist)
        case .singers: catalog.singers.map(LibraryRoute.singer)
        case .writers: catalog.writerGroups().map(LibraryRoute.writers)
        case .songs, .albums, .covers, .setlists: []
        }
    }
}

/// Artwork with its title and details below; the borderless style lifts the artwork when it's in focus.
private struct Lockup<Artwork: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let artwork: Artwork

    var body: some View {
        VStack(spacing: 16) {
            artwork
            LockupText(title: title, subtitle: subtitle)
        }
    }
}

/// A round photo and its name. The borderless style lifts the square image inside the circle, where it doesn't
/// show, so this lifts the circle itself.
private struct PortraitLockup: View {
    let route: LibraryRoute
    let summary: String

    @Environment(\.isFocused) private var isFocused

    var body: some View {
        VStack(spacing: 16) {
            TVArtwork(appleMusicID: route.appleMusicID, placeholder: route.placeholder)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(.circle)
                .scaleEffect(isFocused ? 1.12 : 1)
                .shadow(color: .black.opacity(isFocused ? 0.5 : 0), radius: 20, y: 14)
            LockupText(title: route.title, subtitle: summary)
                .offset(y: isFocused ? 14 : 0)
        }
        .animation(.smooth(duration: 0.2), value: isFocused)
    }
}

private struct PortraitButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

private struct LockupText: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.callout)
                .lineLimit(2)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .multilineTextAlignment(.center)
    }
}

/// A cover or photo from Apple Music that fills its frame, with the placeholder symbol when there's none. It's an
/// `Image`, which the borderless button style lifts when the lockup has focus.
struct TVArtwork: View {
    let appleMusicID: String?
    let placeholder: String?

    var body: some View {
        let store = ArtworkStore.shared
        Group {
            if let image = store.image(for: appleMusicID, width: Self.pixels, height: Self.pixels) {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .scaledToFill()
            } else if let placeholder {
                Image(systemName: placeholder)
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.fill.tertiary)
            } else {
                Color.clear
            }
        }
        .task(id: store.url(for: appleMusicID, width: Self.pixels, height: Self.pixels)) {
            await store.download(appleMusicID, width: Self.pixels, height: Self.pixels)
        }
    }

    private static let pixels = 600
}
#endif

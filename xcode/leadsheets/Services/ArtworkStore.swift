import DeadSheetsKit
import Foundation
import ImageIO
import MusicKit
import Observation
import os

/// Album covers and artist photos from the Apple Music catalog, keyed by Apple Music ID. MusicKit only answers
/// catalog requests once Apple Music access is allowed, so until then there's no artwork.
@Observable
final class ArtworkStore {
    static let shared = ArtworkStore()

    private(set) var artworks: [String: MusicKit.Artwork] = [:]
    private var images: [URL: CGImage] = [:]
    @ObservationIgnored private var downloads: [URL: Task<CGImage?, Never>] = [:]
    @ObservationIgnored private var loading: Task<Void, Never>?
    @ObservationIgnored private var completedRequests: Set<ArtworkRequest> = []
    private let catalogRequests = Catalog.bundled.artworkRequests

    private init() {}

    func artwork(for appleMusicID: String?) -> MusicKit.Artwork? {
        appleMusicID.flatMap { artworks[$0] }
    }

    func url(for appleMusicID: String?, width: Int, height: Int) -> URL? {
        artwork(for: appleMusicID)?.url(width: width, height: height)
    }

    /// Successful batches, including IDs without artwork, are not fetched again. Failed batches can retry.
    func load() async {
        let requests = catalogRequests.filter { !completedRequests.contains($0) }
        guard !requests.isEmpty, !Self.isDisabled else { return }
        let loading =
            self.loading
            ?? Task {
                await fetch(requests)
                self.loading = nil
            }
        self.loading = loading
        await loading.value
    }

    /// The image at this size, once `download` has fetched it.
    func image(for appleMusicID: String?, width: Int, height: Int) -> CGImage? {
        url(for: appleMusicID, width: width, height: height).flatMap { images[$0] }
    }

    /// Fetches the image at this size unless it already has it. Callers asking for one that's on its way share the
    /// download.
    @discardableResult
    func download(_ appleMusicID: String?, width: Int, height: Int) async -> CGImage? {
        guard let url = url(for: appleMusicID, width: width, height: height) else { return nil }
        if let image = images[url] {
            return image
        }
        let download =
            downloads[url]
            ?? Task {
                guard let data = try? await URLSession.shared.data(from: url).0,
                    let source = CGImageSourceCreateWithData(data as CFData, nil)
                else {
                    return nil
                }
                return CGImageSourceCreateImageAtIndex(source, 0, nil)
            }
        downloads[url] = download
        let image = await download.value
        downloads[url] = nil
        images[url] = image
        return image
    }

    private func fetch(_ requests: [ArtworkRequest]) async {
        guard await MusicAuthorization.request() == .authorized else { return }
        for request in requests {
            do {
                switch request.kind {
                case .albums:
                    let albums = try await MusicCatalogResourceRequest<MusicKit.Album>(
                        matching: \.id, memberOf: request.ids.map { MusicItemID($0) }
                    ).response().items
                    for album in albums {
                        artworks[album.id.rawValue] = album.artwork
                    }
                case .artists:
                    let artists = try await MusicCatalogResourceRequest<MusicKit.Artist>(
                        matching: \.id, memberOf: request.ids.map { MusicItemID($0) }
                    ).response().items
                    for artist in artists {
                        artworks[artist.id.rawValue] = artist.artwork
                    }
                }
                completedRequests.insert(request)
            } catch {
                Logger.music.error("Couldn't load artwork: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// UI tests launch with this, so the Apple Music prompt doesn't cover the app.
    private static let isDisabled = ProcessInfo.processInfo.arguments.contains("-noArtwork")
}

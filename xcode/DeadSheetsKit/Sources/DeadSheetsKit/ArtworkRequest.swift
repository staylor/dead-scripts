public struct ArtworkRequest: Hashable, Sendable {
    public enum Kind: Hashable, Sendable {
        case albums
        case artists

        fileprivate var maximumIDs: Int {
            switch self {
            case .albums: 100
            case .artists: 25
            }
        }
    }

    public let kind: Kind
    public let ids: [String]
}

extension Catalog {
    /// Apple Music limits album lookups to 100 IDs and artist lookups to 25.
    public var artworkRequests: [ArtworkRequest] {
        requests(for: albumAppleMusicIDs, kind: .albums) + requests(for: artistAppleMusicIDs, kind: .artists)
    }

    private func requests(for ids: [String], kind: ArtworkRequest.Kind) -> [ArtworkRequest] {
        stride(from: 0, to: ids.count, by: kind.maximumIDs).map { start in
            ArtworkRequest(kind: kind, ids: Array(ids[start..<min(start + kind.maximumIDs, ids.count)]))
        }
    }
}

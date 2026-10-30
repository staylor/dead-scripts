import Foundation

public struct Song: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let sheetFileName: String
    public let lyrics: String
    public let discNumber: Int?
    public let trackNumber: Int?
    public let isCover: Bool
    public let appleMusicID: String?

    public let albumID: Album.ID
    public let albumTitle: String
    public let albumReleaseYear: Int?
    public let albumAppleMusicID: String?
    public let artistID: Artist.ID
    public let artistName: String

    public let singer: Person?
    public let credits: [Credit]

    public var artistAndAlbum: String {
        "\(artistName) · \(albumTitle)"
    }
}

public struct Album: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let releaseYear: Int?
    public let appleMusicID: String?
    public let artistID: Artist.ID
    public let artistName: String
    /// In disc and track order.
    public let songIDs: [Song.ID]
}

public struct Artist: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let appleMusicID: String?
    public let albumIDs: [Album.ID]
    public let songIDs: [Song.ID]
}

public struct Person: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let appleMusicID: String?
}

public enum Role: String, CaseIterable, Comparable, Hashable, Sendable {
    case lyrics
    case music

    public var title: String {
        switch self {
        case .lyrics: "Lyrics"
        case .music: "Music"
        }
    }

    public static func < (lhs: Role, rhs: Role) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct Credit: Hashable, Sendable {
    public let person: Person
    public let role: Role
}

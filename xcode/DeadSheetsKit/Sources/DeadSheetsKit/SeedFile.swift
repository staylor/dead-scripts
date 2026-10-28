import Foundation

/// The shape of `seeds.json`, as written by `src/xcode/generate.ts`.
struct SeedFile: Decodable {
    struct Artist: Decodable {
        let name: String
        let slug: String?
        let appleMusicId: String?
        let albums: [Album]?
    }

    struct Album: Decodable {
        let name: String
        let slug: String
        let releaseYear: Int?
        let appleMusicId: String?
        let songs: [Song]?
    }

    struct Song: Decodable {
        let name: String
        let slug: String
        let fileName: String
        let lyrics: String?
        let singer: String?
        /// `[writerSlug, contribution]` pairs.
        let writers: [[String]]?
        let songType: String?
        let discNumber: Int?
        let trackNumber: Int?
        let appleMusicId: String?
    }

    struct Singer: Decodable {
        let name: String
        let slug: String
        let appleMusicId: String?
    }

    struct Writer: Decodable {
        let name: String
        let slug: String
        let contribution: String
    }

    let artists: [Artist]
    let singers: [Singer]
    let writers: [Writer]
}

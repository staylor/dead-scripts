import Foundation
import SwiftData

@Model
class Artist {
    @Attribute(.unique) var id: UUID
    var name: String
    var imageFileName: String? // For artist photos

    @Relationship(inverse: \Song.artist)
    var songs: [Song]?

    @Relationship(inverse: \Album.artist)
    var albums: [Album]?

    init(name: String, imageFileName: String? = nil) {
        self.id = UUID()
        self.name = name
        self.imageFileName = imageFileName
    }
}

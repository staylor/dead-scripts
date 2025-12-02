import Foundation
import SwiftData

@Model
class Singer {
    @Attribute(.unique) var id: UUID
    var name: String
    var imageFileName: String? // For artist photos

    @Relationship(inverse: \Song.singer)
    var songs: [Song]?

    init(name: String, imageFileName: String? = nil) {
        self.id = UUID()
        self.name = name
        self.imageFileName = imageFileName
    }
}

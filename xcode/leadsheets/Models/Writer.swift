import Foundation
import SwiftData

@Model
class Writer {
    @Attribute(.unique) var id: UUID
    var name: String
    var contribution: String
    var imageFileName: String? // For artist photos

    @Relationship(inverse: \Song.writers)
    var songs: [Song]?

    init(name: String, contribution: String, imageFileName: String? = nil) {
        self.id = UUID()
        self.name = name
        self.contribution = contribution
        self.imageFileName = imageFileName
    }
}

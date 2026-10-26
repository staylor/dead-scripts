import Foundation

@testable import DeadSheetsKit

enum Fixtures {
    static let catalog: Catalog = {
        do {
            return try Catalog(seedData: Data(seeds.utf8))
        } catch {
            fatalError("Fixture seeds don't decode: \(error)")
        }
    }()

    static func song(_ id: Song.ID) -> Song {
        guard let song = catalog.song(id: id) else { fatalError("No fixture song \(id)") }
        return song
    }

    static let seeds = """
        {
          "artists": [
            {
              "name": "Grateful Dead",
              "imageFileName": "grateful-dead.jpg",
              "albums": [
                {
                  "name": "American Beauty",
                  "slug": "american-beauty",
                  "releaseYear": 1970,
                  "coverArtFileName": "american-beauty.jpg",
                  "songs": [
                    {
                      "trackNumber": 8, "name": "Ripple", "slug": "ripple", "fileName": "Ripple Score.pdf",
                      "lyrics": "If my words did glow\\n\\nChorus:\\nRipple in still water", "singer": "jerry-garcia",
                      "writers": [["robert-hunter", "lyrics"], ["jerry-garcia", "music"]], "appleMusicId": "1"
                    },
                    {
                      "trackNumber": 1, "name": "Box of Rain", "slug": "box-of-rain", "fileName": "Box of Rain Score.pdf",
                      "lyrics": "Look out of any window", "singer": "phil-lesh",
                      "writers": [["robert-hunter", "lyrics"], ["phil-lesh", "music"]], "appleMusicId": "2"
                    },
                    {
                      "trackNumber": 3, "name": "Friend of the Devil", "slug": "friend-of-the-devil",
                      "fileName": "Friend of the Devil Score.pdf", "lyrics": "I lit out from Reno", "singer": "jerry-garcia",
                      "writers": [["robert-hunter", "lyrics"], ["jerry-garcia", "music"], ["john-dawson", "music"]]
                    }
                  ]
                },
                {
                  "name": "Grateful Dead (Skull & Roses)",
                  "slug": "skull-and-roses",
                  "releaseYear": 1971,
                  "songs": [
                    {
                      "trackNumber": 2, "songType": "cover", "name": "Big Boss Man", "slug": "big-boss-man",
                      "fileName": "Big Boss Man Score.pdf", "lyrics": "Big boss man, can't you hear me", "singer": "pigpen",
                      "writers": [["al-smith", "music"], ["luther-dixon", "lyrics"]]
                    }
                  ]
                },
                {
                  "name": "The Grateful Dead",
                  "slug": "grateful-dead-album",
                  "releaseYear": 1967,
                  "songs": [
                    {
                      "trackNumber": 9, "songType": "cover", "name": "Morning Dew", "slug": "morning-dew",
                      "fileName": "Morning Dew Score.pdf", "lyrics": "Walk me out in the morning dew", "singer": "jerry-garcia",
                      "writers": [["bonnie-dobson", "lyrics"], ["bonnie-dobson", "music"]], "appleMusicId": ""
                    }
                  ]
                }
              ]
            },
            {
              "name": "Jerry Garcia",
              "slug": "jerry-garcia",
              "albums": [
                {
                  "name": "Garcia",
                  "slug": "garcia",
                  "releaseYear": 1972,
                  "songs": [
                    {
                      "discNumber": 1, "trackNumber": 4, "name": "Sugaree", "slug": "sugaree", "fileName": "Sugaree Score.pdf",
                      "lyrics": "When they come to take you down", "singer": "jerry-garcia",
                      "writers": [["robert-hunter", "lyrics"], ["jerry-garcia", "music"]]
                    }
                  ]
                }
              ]
            }
          ],
          "singers": [
            { "name": "Jerry Garcia", "slug": "jerry-garcia", "imageFileName": "jerry-garcia.jpg" },
            { "name": "Phil Lesh", "slug": "phil-lesh", "imageFileName": "phil-lesh.jpg" },
            { "name": "Ron \\"Pigpen\\" McKernan", "slug": "pigpen", "imageFileName": "pigpen.jpg" }
          ],
          "writers": [
            { "name": "Robert Hunter", "slug": "robert-hunter", "contribution": "lyrics" },
            { "name": "Jerry Garcia", "slug": "jerry-garcia", "contribution": "music" },
            { "name": "John Dawson", "slug": "john-dawson", "contribution": "music" },
            { "name": "Phil Lesh", "slug": "phil-lesh", "contribution": "music" },
            { "name": "Al Smith", "slug": "al-smith", "contribution": "music" },
            { "name": "Luther Dixon", "slug": "luther-dixon", "contribution": "lyrics" },
            { "name": "Bonnie Dobson", "slug": "bonnie-dobson", "contribution": "lyrics" },
            { "name": "Bonnie Dobson", "slug": "bonnie-dobson", "contribution": "music" }
          ]
        }
        """
}

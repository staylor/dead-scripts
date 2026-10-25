import os

extension Logger {
    private static let subsystem = "wonderboymusic.leadsheets"

    static let catalog = Logger(subsystem: subsystem, category: "Catalog")
    static let carPlay = Logger(subsystem: subsystem, category: "CarPlay")
    static let music = Logger(subsystem: subsystem, category: "Music")
    static let sync = Logger(subsystem: subsystem, category: "Sync")
}

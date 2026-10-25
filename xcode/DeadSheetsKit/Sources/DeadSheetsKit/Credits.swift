import Foundation

extension Song {
    /// "Lyrics: Robert Hunter, Music: Jerry Garcia", or "Music & Lyrics: …" when the same
    /// people wrote both.
    public var creditsText: String {
        guard !credits.isEmpty else { return "Unknown Writer" }

        let namesByRole = Dictionary(grouping: credits, by: \.role)
            .mapValues { $0.map(\.person.name).sorted() }
        let music = namesByRole[.music] ?? []
        let lyrics = namesByRole[.lyrics] ?? []

        if !music.isEmpty, music == lyrics {
            return "Music & Lyrics: \(Self.list(music))"
        }
        return namesByRole.keys.sorted()
            .map { "\($0.title): \(Self.list(namesByRole[$0] ?? []))" }
            .joined(separator: ", ")
    }

    /// "A", "A & B", "A, B & C".
    static func list(_ names: [String]) -> String {
        guard let last = names.last else { return "" }
        let rest = names.dropLast()
        return rest.isEmpty ? last : "\(rest.joined(separator: ", ")) & \(last)"
    }
}

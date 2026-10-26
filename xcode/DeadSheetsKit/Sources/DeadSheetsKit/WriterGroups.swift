import Foundation

/// One row in "By Writer": a person, or people who only ever wrote together, with their songs.
public struct WriterGroup: Identifiable, Hashable, Sendable {
    public let id: String
    /// Sorted by name.
    public let people: [Person]
    public let roles: [Role]
    /// Sorted by title.
    public let songs: [Song]

    public var name: String {
        people.map(\.name).joined(separator: " & ")
    }

    /// "Lyrics & Music".
    public var rolesText: String {
        roles.map(\.title).joined(separator: " & ")
    }

    public var imageFileName: String? {
        people.count == 1 ? people[0].imageFileName : nil
    }

    init(people: [Person], roles: Set<Role>, songs: [Song]) {
        var seen: Set<Person.ID> = []
        self.people =
            people
            .filter { seen.insert($0.id).inserted }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        self.roles = roles.sorted()
        self.songs = songs
        id = self.people.map(\.id).joined(separator: "+") + ":" + self.roles.map(\.rawValue).joined(separator: "+")
    }
}

extension Catalog {
    /// Writers whose name or role matches `query`, grouped so that each row has a distinct set of songs.
    ///
    /// A person credited for several roles on exactly the same songs gets one row ("Music & Lyrics");
    /// otherwise each role is its own row. Rows with identical songs are then merged, so writers who
    /// only ever worked together appear once.
    public func writerGroups(matching query: String = "") -> [WriterGroup] {
        struct Entry {
            let person: Person
            let role: Role
            var songIDs: Set<Song.ID>
        }

        var entries: [CreditKey: Entry] = [:]
        for song in songs {
            for credit in song.credits {
                let key = CreditKey(personID: credit.person.id, role: credit.role)
                entries[key, default: Entry(person: credit.person, role: credit.role, songIDs: [])]
                    .songIDs.insert(song.id)
            }
        }

        let matching = entries.values.filter { entry in
            query.isEmpty
                || entry.person.name.localizedStandardContains(query)
                || entry.role.title.localizedStandardContains(query)
        }

        var individuals: [(people: [Person], roles: Set<Role>, songIDs: Set<Song.ID>)] = []
        for (_, personEntries) in Dictionary(grouping: matching, by: \.person.id) {
            let songSets = Set(personEntries.map(\.songIDs))
            if personEntries.count > 1, songSets.count == 1, let songIDs = songSets.first {
                individuals.append(([personEntries[0].person], Set(personEntries.map(\.role)), songIDs))
            } else {
                for entry in personEntries {
                    individuals.append(([entry.person], [entry.role], entry.songIDs))
                }
            }
        }

        return Dictionary(grouping: individuals, by: \.songIDs)
            .map { songIDs, groups in
                WriterGroup(
                    people: groups.flatMap(\.people),
                    roles: groups.reduce(into: Set<Role>()) { $0.formUnion($1.roles) },
                    songs: songIDs.compactMap(song(id:)).sorted(by: Self.titleOrder)
                )
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}

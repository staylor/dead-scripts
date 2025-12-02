import Foundation

/// Wrapper for grouped writers with combined contributions
///
/// This type represents one or more writers who may have collaborated on songs together.
/// It supports combining multiple contributions (e.g., "Music & Lyrics") and grouping
/// collaborators who always work together on the same songs.
struct GroupedWriter: Identifiable, Hashable {
    let id = UUID()
    let names: [String] // Can be multiple names for collaborators
    let contributions: [String] // e.g., ["Music", "Lyrics"]
    let songs: [Song]
    let imageFileName: String?
    
    /// Returns a display-friendly name, joining multiple collaborators with "&"
    var displayName: String {
        names.sorted().joined(separator: " & ")
    }
    
    /// Returns a display-friendly contribution string, capitalizing and joining with "&"
    var displayContribution: String {
        contributions
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .sorted()
            .joined(separator: " & ")
    }
    
    // MARK: - Hashable Conformance
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: GroupedWriter, rhs: GroupedWriter) -> Bool {
        lhs.id == rhs.id
    }
}

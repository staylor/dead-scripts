import SwiftUI

struct GroupedWritersListView: View {
    let groupedWriters: [GroupedWriter]
    let onSelectWriter: (GroupedWriter) -> Void

    var body: some View {
        PlatformListView(
            items: groupedWriters,
            emptyContent: {
                EmptyStateView(filter: .byWriter)
            },
            rowContent: { groupedWriter in
                GroupedWriterRowView(groupedWriter: groupedWriter)
            },
            onSelect: onSelectWriter
        )
    }
}

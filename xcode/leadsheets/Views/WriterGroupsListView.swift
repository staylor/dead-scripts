import DeadSheetsKit
import SwiftUI

struct WriterGroupsListView: View {
    let groups: [WriterGroup]
    let onSelectGroup: (WriterGroup) -> Void

    var body: some View {
        PlatformListView(
            items: groups,
            emptyContent: {
                EmptyStateView(filter: .byWriter)
            },
            rowContent: { group in
                WriterGroupRowView(group: group)
            },
            onSelect: onSelectGroup
        )
    }
}

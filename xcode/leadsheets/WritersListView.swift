import SwiftUI

struct WritersListView: View {
    let writers: [Writer]
    let onSelectWriter: (Writer) -> Void

    var body: some View {
        PlatformListView(
            items: writers,
            emptyContent: {
                EmptyStateView(filter: .byWriter)
            },
            rowContent: { writer in
                WriterRowView(writer: writer)
            },
            onSelect: onSelectWriter
        )
    }
}

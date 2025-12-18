import SwiftUI

struct SingersListView: View {
    let singers: [Singer]
    let onSelectSinger: (Singer) -> Void

    var body: some View {
        PlatformListView(
            items: singers,
            emptyContent: {
                EmptyStateView(filter: .bySinger)
            },
            rowContent: { singer in
                SingerRowView(singer: singer)
            },
            onSelect: onSelectSinger
        )
    }
}

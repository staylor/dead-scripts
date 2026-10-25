import DeadSheetsKit
import SwiftUI

struct SingerRowView: View {
    let singer: Person

    @Environment(\.catalog) private var catalog

    var body: some View {
        HStack(spacing: 16) {
            CachedImage(
                fileName: singer.imageFileName,
                size: 60,
                clipShape: Circle()
            ) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.pink)
                    .frame(width: 60, height: 60)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(singer.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                let songCount = catalog.songs(sungBy: singer).count
                if songCount > 0 {
                    Text("\(songCount) song\(songCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .rowContainer()
    }
}

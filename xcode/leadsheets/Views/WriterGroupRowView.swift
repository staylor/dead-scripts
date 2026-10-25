import DeadSheetsKit
import SwiftUI

struct WriterGroupRowView: View {
    let group: WriterGroup

    var body: some View {
        HStack(spacing: 16) {
            CachedImage(
                fileName: group.imageFileName,
                size: 60,
                clipShape: Circle()
            ) {
                Image(systemName: group.people.count > 1 ? "person.2.circle.fill" : "pencil.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                    .frame(width: 60, height: 60)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(group.rolesText)
                        .font(.caption)
                        .foregroundColor(.pink)

                    let songCount = group.songs.count
                    if songCount > 0 {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(songCount) song\(songCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .rowContainer()
    }
}

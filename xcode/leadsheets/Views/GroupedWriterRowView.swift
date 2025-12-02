import SwiftUI

struct GroupedWriterRowView: View {
    let groupedWriter: GroupedWriter
    
    var body: some View {
        HStack(spacing: 16) {
            CachedImage(
                fileName: groupedWriter.imageFileName,
                size: 60,
                clipShape: Circle()
            ) {
                Image(systemName: groupedWriter.names.count > 1 ? "person.2.circle.fill" : "pencil.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                    .frame(width: 60, height: 60)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(groupedWriter.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(groupedWriter.displayContribution)
                        .font(.caption)
                        .foregroundColor(.pink)

                    let songCount = groupedWriter.songs.count
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

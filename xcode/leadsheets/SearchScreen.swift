import SwiftUI

struct SearchScreen: View {
    @Binding var searchText: String
    let songs: [Song]
    let onSelect: (Song) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Title
            HStack {
                Text("Dead Sheets")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 10)
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search songs...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.bottom)
            
            // Results List
            if songs.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 64))
                        .foregroundColor(.gray)
                    Text("No songs found")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                Spacer()
            } else {
                List(songs) { song in
                    Button(action: { onSelect(song) }) {
                        SongRowView(song: song)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }
}

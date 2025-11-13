import SwiftUI

/// A platform-adaptive list view that handles the differences between macOS, iOS, tvOS, and watchOS
struct PlatformListView<Item: Identifiable, RowContent: View, EmptyContent: View>: View {
    let items: [Item]
    let emptyContent: EmptyContent
    let rowContent: (Item) -> RowContent
    let onSelect: (Item) -> Void
    
    init(
        items: [Item],
        @ViewBuilder emptyContent: () -> EmptyContent,
        @ViewBuilder rowContent: @escaping (Item) -> RowContent,
        onSelect: @escaping (Item) -> Void
    ) {
        self.items = items
        self.emptyContent = emptyContent()
        self.rowContent = rowContent
        self.onSelect = onSelect
    }
    
    var body: some View {
        Group {
            if items.isEmpty {
                emptyContent
            } else {
                List(items) { item in
                    itemCell(for: item)
                }
                .applyListStyle()
            }
        }
    }
    
    // MARK: - Platform-Specific Cell
    
    @ViewBuilder
    private func itemCell(for item: Item) -> some View {
        #if os(macOS)
        rowContent(item)
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect(item)
            }
        #elseif os(tvOS)
        Button(action: { onSelect(item) }) {
            rowContent(item)
        }
        .buttonStyle(.card)
        #elseif os(watchOS)
        Button(action: { onSelect(item) }) {
            rowContent(item)
        }
        .buttonStyle(.plain)
        #else // iOS, iPadOS
        Button(action: { onSelect(item) }) {
            rowContent(item)
        }
        .buttonStyle(.plain)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        #endif
    }
}

// MARK: - List Style Extension

private extension View {
    @ViewBuilder
    func applyListStyle() -> some View {
        #if os(iOS)
        self
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        #elseif os(tvOS)
        self.listStyle(.plain)
        #else
        self
        #endif
    }
}

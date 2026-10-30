public struct CatalogPage: Sendable {
    public let range: Range<Int>
    public let previous: Int?
    public let next: Int?

    public init(itemCount: Int, maximumItemCount: Int, index: Int = 0) {
        precondition(itemCount >= 0 && maximumItemCount >= 3)
        let capacity = itemCount <= maximumItemCount ? maximumItemCount : maximumItemCount - 2
        let last = itemCount == 0 ? 0 : (itemCount - 1) / capacity
        let page = min(max(index, 0), last)
        let start = page * capacity
        range = start..<(start + min(capacity, itemCount - start))
        previous = page > 0 ? page - 1 : nil
        next = page < last ? page + 1 : nil
    }
}

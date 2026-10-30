import Testing

@testable import DeadSheetsKit

struct CatalogPageTests {
    @Test(arguments: [0, 1, 499, 500, 501, 1000, 10000])
    func everyItemIsReachableWithoutExceedingTheTemplateLimit(_ count: Int) {
        var index: Int? = 0
        var visited: [Int] = []
        while let current = index {
            let page = CatalogPage(itemCount: count, maximumItemCount: 500, index: current)
            let controls = (page.previous == nil ? 0 : 1) + (page.next == nil ? 0 : 1)
            #expect(page.range.count + controls <= 500)
            #expect(page.previous == (current == 0 ? nil : current - 1))
            visited.append(contentsOf: page.range)
            index = page.next
        }
        #expect(visited == Array(0..<count))
    }

    @Test func catalogsWithinTheLimitDoNotNeedPagingControls() {
        let page = CatalogPage(itemCount: 500, maximumItemCount: 500)
        #expect(page.range == 0..<500)
        #expect(page.previous == nil)
        #expect(page.next == nil)
    }

    @Test func invalidPageIndicesAreClamped() {
        #expect(CatalogPage(itemCount: 501, maximumItemCount: 500, index: -1).range == 0..<498)
        #expect(CatalogPage(itemCount: 501, maximumItemCount: 500, index: .max).range == 498..<501)
    }
}

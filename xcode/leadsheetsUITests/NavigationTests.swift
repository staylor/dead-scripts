import XCTest

/// iPhone flows: the split view collapses into a navigation stack.
final class NavigationTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testReturningFromASongKeepsTheBrowsingState() {
        let app = launch()
        app.segmentedControls.buttons["Albums"].tap()
        element("album-american-beauty", in: app).tap()
        XCTAssertTrue(app.navigationBars["American Beauty"].waitForExistence(timeout: 5))

        element("song-ripple", in: app).tap()
        XCTAssertTrue(app.navigationBars["Ripple"].waitForExistence(timeout: 5))
        attachScreenshot("Sheet", of: app)

        app.navigationBars["Ripple"].buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["American Beauty"].waitForExistence(timeout: 5))
        XCTAssertTrue(element("song-ripple", in: app).exists)

        app.navigationBars["American Beauty"].buttons.firstMatch.tap()
        XCTAssertTrue(app.segmentedControls.buttons["Albums"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.segmentedControls.buttons["Albums"].isSelected)
        XCTAssertTrue(element("album-american-beauty", in: app).exists)
    }

    @MainActor
    func testSearchFiltersSongs() {
        let app = launch()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("ripple")

        XCTAssertTrue(element("song-ripple", in: app).waitForExistence(timeout: 5))
        XCTAssertFalse(element("song-box-of-rain", in: app).exists)
        attachScreenshot("Search", of: app)
    }

    @MainActor
    func testLyricsOpenFromTheSheet() {
        let app = launch()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("ripple")
        element("song-ripple", in: app).tap()
        XCTAssertTrue(app.navigationBars["Ripple"].waitForExistence(timeout: 5))

        app.buttons["Lyrics"].tap()
        XCTAssertTrue(app.staticTexts["If my words did glow with the gold of sunshine"].waitForExistence(timeout: 5))
        attachScreenshot("Lyrics", of: app)
    }

    @MainActor
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    @MainActor
    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    @MainActor
    private func attachScreenshot(_ name: String, of app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

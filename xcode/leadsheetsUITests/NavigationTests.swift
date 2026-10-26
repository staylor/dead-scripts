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
        open("album-american-beauty", showing: "American Beauty", in: app)
        open("song-ripple", showing: "Ripple", in: app)
        attachScreenshot("Sheet", of: app)

        goBack(from: "Ripple", in: app)
        XCTAssertTrue(app.navigationBars["American Beauty"].waitForExistence(timeout: 10))
        XCTAssertTrue(element("song-ripple", in: app).exists)

        goBack(from: "American Beauty", in: app)
        XCTAssertTrue(app.segmentedControls.buttons["Albums"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.segmentedControls.buttons["Albums"].isSelected)
        XCTAssertTrue(element("album-american-beauty", in: app).exists)
    }

    @MainActor
    func testSearchFiltersSongs() {
        let app = launch()
        search(for: "ripple", in: app)

        XCTAssertTrue(element("song-ripple", in: app).waitForExistence(timeout: 10))
        XCTAssertFalse(element("song-box-of-rain", in: app).exists)
        attachScreenshot("Search", of: app)
    }

    @MainActor
    func testLyricsOpenFromTheSheet() {
        let app = launch()
        search(for: "ripple", in: app)
        open("song-ripple", showing: "Ripple", in: app)

        app.buttons["Lyrics"].tap()
        XCTAssertTrue(app.staticTexts["If my words did glow with the gold of sunshine"].waitForExistence(timeout: 10))
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

    /// On a freshly booted simulator the first tap can land before the field accepts focus, and typing
    /// then fails, so tap until it has focus.
    @MainActor
    private func search(for text: String, in app: XCUIApplication) {
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        let hasFocus = NSPredicate(format: "hasKeyboardFocus == true")
        for _ in 0..<5 where !hasFocus.evaluate(with: field) {
            field.tap()
            _ = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: hasFocus, object: field)], timeout: 2)
        }
        // Return ends editing, so the cursor stops blinking and the app can go idle between steps.
        field.typeText(text + "\n")
    }

    /// Taps until the screen titled `title` appears. On a slow simulator a tap can land mid-animation, or
    /// only end editing in the search field.
    @MainActor
    private func open(_ identifier: String, showing title: String, in app: XCUIApplication) {
        let screen = app.navigationBars[title]
        for _ in 0..<3 where !screen.exists {
            let row = element(identifier, in: app)
            if row.exists {
                row.tap()
            }
            _ = screen.waitForExistence(timeout: 10)
        }
        XCTAssertTrue(screen.exists, "\(identifier) didn't open \(title)")
    }

    @MainActor
    private func goBack(from title: String, in app: XCUIApplication) {
        app.navigationBars[title].buttons["BackButton"].tap()
    }
}

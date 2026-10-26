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
    func testCategoriesBecomeAMenuAtAccessibilityTextSizes() {
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL"]
        app.launch()

        XCTAssertTrue(app.buttons["Browse"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.segmentedControls.firstMatch.exists)
        app.buttons["Browse"].tap()
        app.buttons["Albums"].tap()
        XCTAssertTrue(app.navigationBars["Albums"].waitForExistence(timeout: 10))
        attachScreenshot("Accessibility text size", of: app)
    }

    @MainActor
    func testSettingsShowAboutInformation() {
        let app = launch()
        app.buttons["Settings"].tap()

        XCTAssertTrue(app.switches["Sync with Other Devices"].waitForExistence(timeout: 10))
        attachScreenshot("Settings", of: app)
        XCTAssertTrue(app.buttons["Privacy Policy"].exists)
        let version = NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", "1.0 (1)", "1.0 (1)")
        XCTAssertTrue(app.descendants(matching: .any).matching(version).firstMatch.exists)
    }

    @MainActor
    func testNextAndPreviousFollowTheAlbumsTrackOrder() {
        let app = launch()
        app.segmentedControls.buttons["Albums"].tap()
        element("album-american-beauty", in: app).tap()
        open("song-ripple", showing: "Ripple", in: app)

        app.buttons["Next Song"].tap()
        XCTAssertTrue(app.navigationBars["Brokedown Palace"].waitForExistence(timeout: 10))

        app.buttons["Previous Song"].tap()
        app.buttons["Previous Song"].tap()
        XCTAssertTrue(app.navigationBars["Candyman"].waitForExistence(timeout: 10))
        attachScreenshot("Song navigation", of: app)
    }

    @MainActor
    func testArrowKeysChangeSongs() {
        let app = launch()
        app.segmentedControls.buttons["Albums"].tap()
        element("album-american-beauty", in: app).tap()
        open("song-box-of-rain", showing: "Box of Rain", in: app)
        XCTAssertFalse(app.buttons["Previous Song"].isEnabled)

        app.typeKey(XCUIKeyboardKey.rightArrow, modifierFlags: [])
        XCTAssertTrue(app.navigationBars["Friend of the Devil"].waitForExistence(timeout: 10))

        app.typeKey(XCUIKeyboardKey.leftArrow, modifierFlags: [])
        XCTAssertTrue(app.navigationBars["Box of Rain"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testRelaunchingAfterTheSystemEndsTheAppReopensTheSong() {
        let app = launch()
        app.segmentedControls.buttons["Albums"].tap()
        element("album-american-beauty", in: app).tap()
        open("song-ripple", showing: "Ripple", in: app)

        sendToBackground(app)
        app.terminate()
        app.launch()

        XCTAssertTrue(app.navigationBars["Ripple"].waitForExistence(timeout: 10))
        goBack(from: "Ripple", in: app)
        XCTAssertTrue(app.segmentedControls.buttons["Albums"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.segmentedControls.buttons["Albums"].isSelected)

        // Leave the restored state where the other tests expect to start.
        app.segmentedControls.buttons["Songs"].tap()
        sendToBackground(app)
        app.terminate()
        app.launch()
        XCTAssertTrue(app.segmentedControls.buttons["Songs"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.segmentedControls.buttons["Songs"].isSelected)
    }

    /// Scene storage is saved as the scene moves to the background, so wait for that before ending the app.
    @MainActor
    private func sendToBackground(_ app: XCUIApplication) {
        XCUIDevice.shared.press(.home)
        let inBackground = NSPredicate(
            format: "state == %d OR state == %d",
            XCUIApplication.State.runningBackground.rawValue,
            XCUIApplication.State.runningBackgroundSuspended.rawValue
        )
        _ = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: inBackground, object: app)], timeout: 15)
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

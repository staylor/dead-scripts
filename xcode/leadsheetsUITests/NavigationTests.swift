import XCTest

#if os(iOS)
/// iPhone flows: the split view collapses into a navigation stack.
final class NavigationTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testReturningFromASongKeepsTheBrowsingState() {
        let app = launch()
        select("Albums", in: app)
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
    func testRotatingKeepsThePlaceInTheSheet() {
        let app = launch()
        search(for: "terrapin", in: app)
        open("song-terrapin-station", showing: "Terrapin Station Medley", in: app)
        addTeardownBlock {
            await MainActor.run {
                XCUIDevice.shared.orientation = .portrait
            }
        }

        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        start.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)))
        let portrait = readingPosition(in: app, title: "Terrapin Station Medley")
        XCTAssertGreaterThan(portrait, 0.05)

        XCUIDevice.shared.orientation = .landscapeLeft
        let landscape = readingPosition(in: app, title: "Terrapin Station Medley")
        XCTAssertEqual(landscape, portrait, accuracy: 0.02)

        XCUIDevice.shared.orientation = .portrait
        XCTAssertEqual(readingPosition(in: app, title: "Terrapin Station Medley"), portrait, accuracy: 0.02)
    }

    /// How far down the sheet the bottom of the navigation bar is, once the page stops moving.
    @MainActor
    private func readingPosition(in app: XCUIApplication, title: String) -> CGFloat {
        let page = app.textViews.firstMatch
        XCTAssertTrue(page.waitForExistence(timeout: 10))
        var frame = CGRect.null
        for _ in 0..<20 {
            Thread.sleep(forTimeInterval: 0.5)
            let next = page.frame
            if next == frame { break }
            frame = next
        }
        return (app.navigationBars[title].frame.maxY - frame.minY) / frame.height
    }

    @MainActor
    func testCategoriesBecomeAMenuAtAccessibilityTextSizes() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-inMemoryUserData", "-noArtwork", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL",
        ]
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
        // iOS 27 no longer reports a Link as a button.
        XCTAssertTrue(app.links["Privacy Policy"].exists || app.buttons["Privacy Policy"].exists)
        let version = NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", "1.0 (1)", "1.0 (1)")
        XCTAssertTrue(app.descendants(matching: .any).matching(version).firstMatch.exists)
    }

    @MainActor
    func testUnavailableUserDataKeepsTheCatalogReadableWithoutOfferingUnsavedEdits() {
        let app = XCUIApplication()
        app.launchArguments += ["-noArtwork", "-unavailableUserData"]
        app.launch()
        XCTAssertTrue(element("user-data-unavailable", in: app).waitForExistence(timeout: 10))

        select("Setlists", in: app)
        XCTAssertTrue(app.staticTexts["Setlists Unavailable"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["New Setlist"].isEnabled)

        select("Songs", in: app)
        open("song-alabama-getaway", showing: "Alabama Getaway", in: app)
        XCTAssertFalse(app.buttons["Add to Favorites"].isEnabled)
        XCTAssertFalse(app.buttons["Add to Setlist"].isEnabled)
        XCTAssertTrue(app.textViews.firstMatch.waitForExistence(timeout: 10))
    }

    @MainActor
    func testNextAndPreviousFollowTheAlbumsTrackOrder() {
        let app = launch()
        select("Albums", in: app)
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
        select("Albums", in: app)
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
        select("Albums", in: app)
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
        select("Songs", in: app)
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
        if !app.wait(for: .runningBackground, timeout: 5), !app.wait(for: .runningBackgroundSuspended, timeout: 1) {
            // CI simulators sometimes ignore the Home button; bringing SpringBoard forward backgrounds the app too.
            XCUIApplication(bundleIdentifier: "com.apple.springboard").activate()
            _ = app.wait(for: .runningBackground, timeout: 10)
        }
        // The system writes the saved state to disk shortly after the app leaves the foreground.
        sleep(2)
    }

    @MainActor
    func testFavoritesAppearInTheFavoritesFilter() {
        let app = launch()
        select("Albums", in: app)
        element("album-american-beauty", in: app).tap()
        element("song-ripple", in: app).tap()
        app.buttons["Add to Favorites"].tap()
        XCTAssertTrue(app.buttons["Remove from Favorites"].waitForExistence(timeout: 10))

        goBack(from: "Ripple", in: app)
        goBack(from: "American Beauty", in: app)
        select("Songs", in: app)
        XCTAssertTrue(app.buttons["Filter"].waitForExistence(timeout: 10))
        app.buttons["Filter"].tap()
        app.buttons["Favorites"].tap()

        XCTAssertTrue(app.navigationBars["Favorites"].waitForExistence(timeout: 10))
        XCTAssertTrue(element("song-ripple", in: app).exists)
        XCTAssertFalse(element("song-alabama-getaway", in: app).exists)
    }

    @MainActor
    func testSetlistsPlayInTheOrderSongsWereAdded() {
        let app = launch()
        select("Setlists", in: app)
        app.buttons["New Setlist"].firstMatch.tap()
        let alert = app.alerts["New Setlist"]
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        alert.textFields.firstMatch.typeText("Saturday")
        alert.buttons["Create"].tap()

        open("setlist-Saturday", showing: "Saturday", in: app)
        app.buttons["Add Songs"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Add Songs"].waitForExistence(timeout: 10))
        element("song-althea", in: app).tap()
        element("song-alabama-getaway", in: app).tap()
        app.buttons["Done"].tap()

        open("song-althea", showing: "Althea", in: app)
        app.buttons["Next Song"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Alabama Getaway"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Next Song"].firstMatch.isEnabled)
        attachScreenshot("Setlist", of: app)
    }

    @MainActor
    func testSearchingSetlistsAndDeletingAResultKeepsOtherSetlists() {
        let app = launch()
        select("Setlists", in: app)
        for name in ["Saturday", "Sunday"] {
            app.buttons["New Setlist"].firstMatch.tap()
            let alert = app.alerts["New Setlist"]
            XCTAssertTrue(alert.waitForExistence(timeout: 10))
            alert.textFields.firstMatch.typeText(name)
            alert.buttons["Create"].tap()
            XCTAssertTrue(element("setlist-\(name)", in: app).waitForExistence(timeout: 10))
        }

        search(for: "saturday", in: app)
        XCTAssertTrue(element("setlist-Saturday", in: app).exists)
        XCTAssertFalse(element("setlist-Sunday", in: app).exists)

        element("setlist-Saturday", in: app).swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertTrue(element("setlist-search-empty", in: app).waitForExistence(timeout: 10))

        app.searchFields.firstMatch.buttons["Clear text"].tap()
        XCTAssertTrue(element("setlist-Sunday", in: app).waitForExistence(timeout: 10))
        XCTAssertFalse(element("setlist-Saturday", in: app).exists)
    }

    @MainActor
    func testLandscapeMovesTheSongButtonsUpAndTheLyricsBesideTheSheet() {
        let app = launch()
        search(for: "ripple", in: app)
        open("song-ripple", showing: "Ripple", in: app)
        addTeardownBlock {
            await MainActor.run {
                XCUIDevice.shared.orientation = .portrait
            }
        }

        XCUIDevice.shared.orientation = .landscapeLeft
        let bar = app.navigationBars["Ripple"]
        XCTAssertTrue(bar.buttons["Next Song"].waitForExistence(timeout: 10))
        XCTAssertTrue(bar.buttons["Add to Favorites"].exists)

        app.buttons["Lyrics"].tap()
        let line = app.staticTexts["If my words did glow with the gold of sunshine"]
        XCTAssertTrue(line.waitForExistence(timeout: 10))
        XCTAssertLessThan(app.textViews.firstMatch.frame.midX, line.frame.minX)

        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.buttons["Next Song"].waitForExistence(timeout: 10))
        XCTAssertFalse(bar.buttons["Next Song"].exists)
        XCTAssertTrue(line.waitForExistence(timeout: 10))

        // Dragging the sheet down by its header closes the lyrics; a swipe on the text would scroll it.
        app.staticTexts["Sung by Jerry Garcia"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.99)))
        let closed = NSPredicate(format: "exists == false")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: closed, object: line)], timeout: 10), .completed)
        // If closing the sheet had left the lyrics on, this tap would turn them off.
        app.buttons["Lyrics"].tap()
        XCTAssertTrue(line.waitForExistence(timeout: 10))
    }

    @MainActor
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-inMemoryUserData", "-noArtwork"]
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

    /// Taps a category until it's selected; a tap can be lost while a pop animation is still running.
    @MainActor
    private func select(_ category: String, in app: XCUIApplication) {
        let segment = app.segmentedControls.buttons[category]
        XCTAssertTrue(segment.waitForExistence(timeout: 10))
        let selected = NSPredicate(format: "isSelected == true")
        for _ in 0..<3 where !segment.isSelected {
            segment.tap()
            _ = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: selected, object: segment)], timeout: 3)
        }
        XCTAssertTrue(segment.isSelected, "\(category) wasn't selected")
    }
}
#endif

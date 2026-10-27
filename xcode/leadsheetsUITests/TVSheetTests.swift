import XCTest

#if os(tvOS)
/// Apple TV flows, driven with the Siri Remote.
final class TVSheetTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testTheSheetAndLyricsScrollAndTheSheetZooms() {
        let remote = XCUIRemote.shared
        let app = XCUIApplication()
        app.launchArguments += ["-inMemoryUserData"]
        app.launch()
        let row = element("song-alabama-getaway", in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        press(.down, untilFocusIsOn: app.cells.containing(.any, identifier: "song-alabama-getaway").firstMatch)
        remote.press(.select)

        let sheet = element("sheet", in: app)
        XCTAssertTrue(sheet.waitForExistence(timeout: 10))
        waitForFocus(on: sheet)
        XCTAssertEqual(sheet.value as? String, "Beside the lyrics")
        attachScreenshot("Sheet", of: app)
        remote.press(.down)
        remote.press(.down)
        attachScreenshot("Sheet scrolled", of: app)

        // The focus engine picks the stanza beside the middle of the sheet.
        remote.press(.right)
        let stanza = focusedStanza(in: app)
        press(.down, untilFocusIsOn: element("stanza-\(stanza + 1)", in: app))
        attachScreenshot("Lyrics", of: app)

        press(.left, untilFocusIsOn: sheet)
        remote.press(.select)
        waitForValue("Full width", of: sheet)
        XCTAssertFalse(element("stanza-0", in: app).exists)
        attachScreenshot("Full width", of: app)

        remote.press(.select)
        waitForValue("Zoomed in", of: sheet)
        remote.press(.right)
        remote.press(.down)
        attachScreenshot("Zoomed in", of: app)

        remote.press(.menu)
        waitForValue("Full width", of: sheet)
        remote.press(.menu)
        waitForValue("Beside the lyrics", of: sheet)
        XCTAssertTrue(element("stanza-0", in: app).waitForExistence(timeout: 5))
        remote.press(.menu)
        XCTAssertTrue(row.waitForExistence(timeout: 10))
    }

    @MainActor
    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    @MainActor
    private func waitForFocus(on element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        let focused = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hasFocus == true"), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [focused], timeout: 10), .completed, "\(element) didn't get focus", file: file, line: line)
    }

    @MainActor
    private func focusedStanza(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) -> Int {
        let stanza = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'stanza-' AND hasFocus == true")).firstMatch
        XCTAssertTrue(stanza.waitForExistence(timeout: 10), "No stanza got focus", file: file, line: line)
        return Int(stanza.identifier.dropFirst("stanza-".count)) ?? -1
    }

    /// A press can be lost while an animation is still running, so press until the focus moves.
    @MainActor
    private func press(
        _ button: XCUIRemote.Button,
        untilFocusIsOn element: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let focused = NSPredicate(format: "hasFocus == true")
        for _ in 0..<3 where !element.hasFocus {
            XCUIRemote.shared.press(button)
            _ = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: focused, object: element)], timeout: 3)
        }
        XCTAssertTrue(element.hasFocus, "\(element) didn't get focus", file: file, line: line)
    }

    @MainActor
    private func waitForValue(_ value: String, of element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        let matches = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", value), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [matches], timeout: 10), .completed, "\(element) isn't \(value)", file: file, line: line)
    }

    @MainActor
    private func attachScreenshot(_ name: String, of app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
#endif

import DeadSheetsKit
import Foundation

extension Song {
    var sheetURL: URL? {
        Bundle.main.url(forResource: sheetResourceName, withExtension: "pdf")
    }

    /// The PNG rendering of the sheet that tvOS shows, since tvOS has no PDFKit.
    var sheetImageURL: URL? {
        Bundle.main.url(forResource: sheetResourceName, withExtension: "png")
    }

    private var sheetResourceName: String {
        (sheetFileName as NSString).deletingPathExtension
    }
}

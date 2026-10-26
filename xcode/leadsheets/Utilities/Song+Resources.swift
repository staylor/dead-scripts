import DeadSheetsKit
import Foundation

extension Song {
    var sheetURL: URL? {
        Bundle.main.url(forResource: sheetResourceName, withExtension: "pdf", subdirectory: "pdfs")
    }

    /// The PNG rendering of the sheet that tvOS shows, since tvOS has no PDFKit.
    var sheetImageURL: URL? {
        Bundle.main.url(forResource: sheetResourceName, withExtension: "png", subdirectory: "images")
    }

    private var sheetResourceName: String {
        (sheetFileName as NSString).deletingPathExtension
    }
}

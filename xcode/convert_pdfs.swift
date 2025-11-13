#!/usr/bin/env swift

import Foundation
import PDFKit
import AppKit

let pdfDir = "leadsheets/pdfs"
let outputDir = "leadsheets/images"

// Create output directory
let fileManager = FileManager.default
try? fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

// Get all PDFs
let pdfURL = URL(fileURLWithPath: pdfDir)
guard let pdfFiles = try? fileManager.contentsOfDirectory(at: pdfURL, includingPropertiesForKeys: nil)
    .filter({ $0.pathExtension.lowercased() == "pdf" })
    .sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) else {
    print("❌ Could not read PDF directory")
    exit(1)
}

print("Converting \(pdfFiles.count) PDFs to high-resolution images...")
print("Source: \(pdfDir)")
print("Output: \(outputDir)\n")

var successCount = 0

for (index, pdfURL) in pdfFiles.enumerated() {
    let filename = pdfURL.deletingPathExtension().lastPathComponent
    let outputPath = "\(outputDir)/\(filename).png"
    let outputURL = URL(fileURLWithPath: outputPath)

    print("[\(index + 1)/\(pdfFiles.count)] Converting: \(filename)")

    guard let pdfDocument = PDFDocument(url: pdfURL),
          let page = pdfDocument.page(at: 0) else {
        print("  ⚠️  Could not open PDF")
        continue
    }

    // Get page bounds
    let pageBounds = page.bounds(for: .mediaBox)

    // Create high-resolution image (2x for Retina, suitable for TV)
    let scale: CGFloat = 3.0
    let imageSize = CGSize(
        width: pageBounds.width * scale,
        height: pageBounds.height * scale
    )

    // Create bitmap context
    guard let bitmapRep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(imageSize.width),
        pixelsHigh: Int(imageSize.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        print("  ⚠️  Could not create bitmap")
        continue
    }

    NSGraphicsContext.saveGraphicsState()
    guard let context = NSGraphicsContext(bitmapImageRep: bitmapRep) else {
        print("  ⚠️  Could not create graphics context")
        continue
    }
    NSGraphicsContext.current = context

    // Set white background
    NSColor.white.setFill()
    NSRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height).fill()

    // Scale and render PDF
    let transform = NSAffineTransform()
    transform.scale(by: scale)
    transform.concat()

    page.draw(with: .mediaBox, to: context.cgContext)

    NSGraphicsContext.restoreGraphicsState()

    // Save as PNG
    guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        print("  ⚠️  Could not create PNG data")
        continue
    }

    do {
        try pngData.write(to: outputURL)
        successCount += 1
    } catch {
        print("  ⚠️  Could not write file: \(error)")
    }
}

print("\n✅ Done! Converted \(successCount)/\(pdfFiles.count) PDFs successfully")

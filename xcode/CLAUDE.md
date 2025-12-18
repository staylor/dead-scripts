# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build for macOS
xcodebuild -project leadsheets.xcodeproj -scheme leadsheets -destination 'platform=macOS' build

# Build for iOS Simulator
xcodebuild -project leadsheets.xcodeproj -scheme leadsheets -destination 'platform=iOS Simulator,name=iPhone 16' build

# Build for watchOS Simulator
xcodebuild -project leadsheets.xcodeproj -scheme "leadsheets.watch" -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)' build
```

## Custom Slash Commands

- `/swift-check [file]` - Analyze Swift files for SwiftUI best practices, memory leaks, and performance issues

## Architecture Overview

**Dead Sheets** is a multi-platform SwiftUI app (iOS, macOS, watchOS, tvOS, CarPlay) for viewing music lead sheets (PDFs) with lyrics.

### Key Architectural Patterns

1. **Shared ModelContainer** - `SharedModelContainer.shared` in `LeadSheetsApp.swift` provides a singleton SwiftData container used by both the main app and CarPlay

2. **Hash-based Import** - `DataImportManager` uses SHA256 to detect changes in `seeds.json`, only reimporting when the file changes

3. **Cross-device Sync**:
   - `CloudSyncManager` - CloudKit sync between iPhone/iPad/Mac (async/await APIs)
   - `WatchConnectivityManager` - Direct iPhone↔Watch sync via WatchConnectivity

4. **Platform Abstraction**:
   - `#if os(iOS)` / `#if os(macOS)` for platform-specific code
   - `PDFKitView+iOS.swift` / `PDFKitView+macOS.swift` for platform implementations
   - `PlatformColors` / `PlatformListView` for cross-platform styling

5. **Notification-based Updates** - `.songsDidImport` notification triggers CarPlay refresh after import completes

### Data Flow

```
seeds.json → DataImportService (actor) → SwiftData Models → @Query in Views
```

### Project Structure

```
leadsheets/
├── Models/          # SwiftData models (Song, Album, Artist, Singer, Writer)
├── Views/           # SwiftUI views (*ListView, *RowView, *Screen)
├── Services/        # Managers (DataImport, CloudSync, WatchConnectivity, ImageLoader)
├── Utilities/       # Helpers (PDFKitView, PlatformColors, CachedImage)
├── Resources/       # Assets, seeds.json, pdfs/, images/
└── LeadSheetsApp.swift, CarPlaySceneDelegate.swift

leadsheets.watch/    # watchOS target
```

### SwiftData Models

- `Song` - Core entity with PDF filename, lyrics, Apple Music ID
- `Album` - Has songs, cover art, release year
- `Artist` - Performing band (has albums and songs)
- `Singer` - Original vocalist (for bands with multiple singers)
- `Writer` - Songwriter with contribution type (music/lyrics)
- `GroupedWriter` - Non-persisted helper for UI grouping

### Platform-specific Behaviors

| Platform | PDF Viewer               | Lyrics            | Sync              |
| -------- | ------------------------ | ----------------- | ----------------- |
| iOS      | Full-screen PDFKit       | Draggable overlay | CloudKit + Watch  |
| macOS    | 3-column split           | Inspector panel   | CloudKit          |
| tvOS     | Image viewer (no PDFKit) | Side panel        | None              |
| watchOS  | None                     | ScrollView        | WatchConnectivity |
| CarPlay  | None                     | None              | Shared container  |

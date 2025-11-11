# Migration Guide: PDFDocument → SwiftData

## Overview

Your app has been migrated from loading data from JSON every launch to using **SwiftData** for persistent, fast, and scalable data management.

## What Changed

### ✅ New Files Created

1. **Song.swift** - Core data models
   - `Song` - Represents a song with PDF and metadata
   - `Artist` - Artist information
   - `Album` - Album information
   - `Tag` - Categorization tags

2. **DataImportService.swift** - Handles JSON import
   - `importLegacyJSON()` - Imports your existing songs.json
   - `importStructuredJSON()` - For future enhanced JSON format

3. **PDFKitView.swift** - PDF display component
   - Wrapper for UIKit's PDFView in SwiftUI

4. **AdvancedQueryExamples.swift** - Reference for future features
   - Shows how to query, filter, and display data

5. **songs-new-format-example.json** - Template for future imports

### ✅ Updated Files

1. **LeadSheetsApp.swift**
   - Added `.modelContainer()` to initialize SwiftData

2. **ContentView.swift**
   - Replaced `@State var samplePDFs` with `@Query var allSongs`
   - Added automatic import on first launch
   - Enhanced search across song, artist, album, and lyrics

3. **SearchScreen.swift**
   - Updated to use `Song` instead of `PDFDocument`

4. **PDFRowView.swift → SongRowView.swift**
   - Renamed and updated to show artist/album info
   - Added backward compatibility alias

5. **PDFViewerScreen.swift**
   - Updated to use `Song` model

6. **LyricsOverlay.swift**
   - Updated to display artist and album separately
   - Better layout with divider

## Data Flow

### Before:

```
JSON file → Load on every app launch → Array in memory → Filter/search
```

### After:

```
JSON file → Import once → SwiftData database → Fast queries → Lazy loading
```

## First Launch Behavior

1. App checks `@AppStorage("hasImportedInitialData")`
2. If `false`, imports `songs.json` into SwiftData
3. Shows loading indicator during import
4. Sets flag to `true` to prevent re-import
5. From then on, queries database directly

## Adding New Songs

### Option 1: Keep Legacy Format (Current songs.json)

```json
[
  {
    "name": "Song Name",
    "albumName": "Album Name",
    "fileName": "song-file.pdf",
    "lyrics": "Song lyrics here..."
  }
]
```

### Option 2: Use New Enhanced Format

```json
[
  {
    "name": "Song Name",
    "fileName": "song-file.pdf",
    "lyrics": "Song lyrics...",
    "trackNumber": 1,
    "releaseYear": 2024,
    "artist": {
      "name": "Artist Name",
      "biography": "Bio...",
      "imageFileName": "artist.jpg"
    },
    "album": {
      "name": "Album Name",
      "releaseDate": "2024-01-01T00:00:00Z",
      "coverArtFileName": "cover.jpg"
    },
    "tags": ["Jazz", "Standards"]
  }
]
```

## Performance Benefits

| Metric      | Before (JSON)      | After (SwiftData)           |
| ----------- | ------------------ | --------------------------- |
| App Launch  | Parse entire JSON  | Instant database connection |
| Search      | O(n) scan          | Indexed query               |
| Memory      | All songs in RAM   | Only what's needed          |
| Filter      | Re-scan array      | Database predicate          |
| Scalability | Degrades with size | Stays fast                  |

## Future Features Enabled

With SwiftData, you can now easily add:

- ✅ **Playlists** - Create custom collections
- ✅ **Favorites** - Mark songs as favorites
- ✅ **Play History** - Track recently played
- ✅ **Advanced Filters** - By year, genre, key, etc.
- ✅ **Statistics** - Total songs, etc.
- ✅ **CloudKit Sync** - Sync across devices
- ✅ **User Ratings** - Rate songs 1-5 stars
- ✅ **Custom Sorting** - User preferences

## Resetting Data

If you need to re-import from JSON:

1. In Xcode: **Product → Scheme → Edit Scheme**
2. Run → Arguments → Launch Arguments
3. Add: `-hasImportedInitialData NO`

Or programmatically:

```swift
UserDefaults.standard.set(false, forKey: "hasImportedInitialData")
```

## Backward Compatibility

The old `PDFDocument` struct still exists but is no longer used. You can safely delete it once you've verified everything works.

A `typealias PDFRowView = SongRowView` provides backward compatibility if needed.

## Testing

The preview provider now uses in-memory storage:

```swift
.modelContainer(for: [Song.self, Artist.self, Album.self, Tag.self], inMemory: true)
```

## Questions?

Check `AdvancedQueryExamples.swift` for examples of:

- Filtering by artist, year, tag
- Complex searches
- Grouping by album
- Statistical views

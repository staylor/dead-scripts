# Migration Guide: PDFDocument → SwiftData

## What Changed

Your app has been migrated from using a simple `PDFDocument` struct with JSON loading to a full SwiftData architecture.

### Old Architecture

```
JSON file → Array<PDFDocument> → Filter in memory
```

### New Architecture

```
JSON seed file → SwiftData database → Query with predicates
```

---

## Files Modified

### ✅ Created

- **Song.swift** - Main data models (Song, Artist, Album, Tag)
- **DataImportService.swift** - Handles JSON → SwiftData import
- **SongRowView.swift** - Row view for songs (replaces PDFRowView for new model)
- **AdvancedQueryExamples.swift** - Examples of advanced queries
- **songs-new-format-example.json** - Example of new JSON structure

### ✅ Updated

- **LeadSheetsApp.swift** - Added `.modelContainer` for SwiftData
- **ContentView.swift** - Now uses `@Query` and imports data on first launch
- **SearchScreen.swift** - Changed from `pdfs: [PDFDocument]` to `songs: [Song]`
- **PDFViewerScreen.swift** - Changed from `pdf: PDFDocument` to `song: Song`
- **LyricsOverlay.swift** - Changed from `pdf: PDFDocument` to `song: Song`

### ⚠️ Kept (for now)

- **PDFDocument.swift** - Legacy struct (can be removed after migration complete)
- **PDFRowView.swift** - Legacy view (can be removed after migration complete)
- **songs.json** - Your existing JSON file (still used as seed data)

---

## How It Works Now

### First Launch

1. App checks `@AppStorage("hasImportedInitialData")`
2. If `false`, imports `songs.json` via `DataImportService`
3. Creates `Song`, `Artist`, and `Album` objects in SwiftData
4. Sets `hasImportedInitialData = true`
5. Shows songs from database

### Subsequent Launches

1. App loads songs directly from SwiftData (instant)
2. No JSON parsing needed
3. Searches/filters use database queries (fast)

---

## Database Location

SwiftData stores your database at:

```
~/Library/Application Support/[Your App]/default.store
```

To reset the database during development:

- Delete the app from simulator/device
- Or use `modelContainer(for: ..., inMemory: true)` for testing

---

## Adding New Songs

### Option 1: Update songs.json (Simple)

Keep adding to your existing `songs.json`:

```json
[
  {
    "name": "New Song",
    "albumName": "Artist Name - Album Name",
    "fileName": "new-song.pdf",
    "lyrics": "..."
  }
]
```

**To re-import:**

- Delete and reinstall the app, OR
- Add a "Re-import" button in settings that sets `hasImportedInitialData = false`

### Option 2: Use New Structured Format (Recommended for growth)

Create separate JSON files with full structure:

```json
[
  {
    "name": "Blue Bossa",
    "fileName": "blue-bossa.pdf",
    "lyrics": "...",
    "trackNumber": 1,
    "artist": {
      "name": "Kenny Dorham",
      "biography": "..."
    },
    "album": {
      "name": "Page One",
      "releaseYear": 1963
    },
    "tags": ["Jazz", "Bossa Nova"]
  }
]
```

Then import with:

```swift
try await importService.importStructuredJSON(from: "new-songs", into: modelContext)
```

---

## Search Performance

### Before (JSON)

- **Search:** O(n) - scans every song
- **Filter:** Creates new array each time
- **Memory:** All songs always in RAM

### After (SwiftData)

- **Search:** Indexed predicates - much faster
- **Filter:** Query only matching songs
- **Memory:** Lazy loading - only loads what's visible

---

## Future Enhancements

Now that you have SwiftData, you can easily add:

### 1. User Favorites

```swift
// Add to Song model
var isFavorite: Bool = false

// Query favorites
@Query(filter: #Predicate<Song> { $0.isFavorite == true })
private var favorites: [Song]
```

### 2. Play Count & History

```swift
var playCount: Int = 0
var lastPlayed: Date?
```

### 3. Playlists

```swift
@Model
class Playlist {
    var name: String
    @Relationship var songs: [Song]
}
```

### 4. CloudKit Sync

```swift
.modelContainer(for: [Song.self], isCloudKitEnabled: true)
```

### 5. Advanced Search

See `AdvancedQueryExamples.swift` for examples of:

- Filter by artist
- Filter by year range
- Filter by tags
- Group by album
- Recently added
- Statistics

---

## Troubleshooting

### "No songs showing up"

- Check Console for import errors
- Verify `songs.json` is in your bundle
- Try deleting app and reinstalling

### "Database growing too large"

- SwiftData efficiently manages memory
- Only visible songs are fully loaded
- Database is compressed on disk

### "Want to reset everything"

```swift
// Add this in your app for development
Button("Reset Database") {
    try? modelContext.delete(model: Song.self)
    try? modelContext.delete(model: Artist.self)
    try? modelContext.delete(model: Album.self)
    hasImportedInitialData = false
}
```

---

## Next Steps

1. ✅ **Test the migration** - Run the app and verify songs load
2. ✅ **Verify search works** - Test searching by song, artist, album
3. ✅ **Check PDF viewing** - Make sure PDFs still open correctly
4. 🔄 **Plan data structure** - Decide what fields you want to add
5. 🔄 **Create new JSON format** - Start using structured format for new songs
6. 🔄 **Remove legacy code** - Delete PDFDocument.swift and PDFRowView.swift when ready

---

## Questions?

This migration sets you up for long-term growth. The app will stay fast even with thousands of songs, and you can easily add new features like favorites, playlists, and CloudKit sync.

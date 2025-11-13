# Troubleshooting Guide

## Common Issues and Solutions

### Issue: "No songs showing after migration"

**Possible causes:**

1. JSON file not found in bundle
2. JSON format doesn't match expected structure
3. Import failed silently

**Solutions:**

```swift
// Check the console for error messages
// You should see either:
// "Successfully imported X songs"
// or
// "Failed to import data: [error message]"
```

**Quick fix:**

1. Make sure `seeds.json` is in your project
2. Verify it's included in "Copy Bundle Resources" (Build Phases)
3. Reset import flag: Settings → Advanced → Reset Data Import

### Issue: "App crashes on launch"

**Possible cause:** SwiftData model mismatch with existing data

**Solution:**

1. Delete the app from simulator/device
2. Reinstall (this clears the database)
3. Or add migration code (advanced)

### Issue: "Songs imported twice"

**Cause:** Import flag not being set correctly

**Solution:**

```swift
// In ContentView, verify this line exists:
hasImportedInitialData = true
```

### Issue: "Can't delete PDFDocument.swift"

**Reason:** File might still be referenced somewhere

**Solution:**

1. Build the project (`Cmd+B`)
2. Fix any compiler errors pointing to PDFDocument
3. Search project for "PDFDocument" (Cmd+Shift+F)
4. Remove references
5. Right-click file → Delete → Move to Trash

### Issue: "Search not working"

**Check:**

```swift
// Make sure filteredSongs is being used in SearchScreen
SearchScreen(
    searchText: $searchText,
    songs: filteredSongs,  // ← Should be filteredSongs, not allSongs
    onSelect: { song in selectedPDF = song }
)
```

### Issue: "Lyrics not showing"

**Possible causes:**

1. Lyrics field is `nil` or empty in JSON
2. LyricsOverlay not updated

**Solution:**

```json
// In seeds.json, ensure lyrics field exists:
{
  "name": "Song Name",
  "albumName": "Album Name",
  "fileName": "song.pdf",
  "lyrics": "These are the lyrics..." // ← Add this
}
```

### Issue: "PDFs not displaying"

**Check:**

1. PDF files are in project bundle
2. File names match exactly (case-sensitive)
3. PDFKitView is properly implemented

**Debug:**

```swift
// Add to Song model or test:
if let url = song.pdfURL {
    print("PDF URL: \(url)")
    print("File exists: \(FileManager.default.fileExists(atPath: url.path))")
} else {
    print("PDF URL is nil for: \(song.fileName)")
}
```

### Issue: "Performance is slow"

**Check:**

1. How many songs do you have?
2. Is search filtering properly?
3. Are you loading all relationships unnecessarily?

**Optimization:**

```swift
// Instead of:
let allSongs = songManager.fetchAllSongs()
let filtered = allSongs.filter { ... }

// Use SwiftData predicates:
@Query(filter: #Predicate<Song> { song in
    song.name.contains(searchText)
})
```

## Resetting Everything

### Option 1: Delete and Reinstall App

- Easiest method
- Clears all data
- Fresh import on next launch

### Option 2: Reset Import Flag

```swift
// Add this somewhere (like a debug button):
UserDefaults.standard.set(false, forKey: "hasImportedInitialData")
// Then restart app
```

### Option 3: Clear All Data Programmatically

```swift
@Environment(\.modelContext) private var modelContext

func clearAllData() {
    let manager = SongDataManager(modelContext: modelContext)
    manager.deleteAllData()
    UserDefaults.standard.set(false, forKey: "hasImportedInitialData")
}
```

## Debugging Import

Add detailed logging to `DataImportService.swift`:

```swift
func importLegacyJSON(from fileName: String, into context: ModelContext) async throws {
    print("🔍 Looking for: \(fileName).json")

    guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
        print("❌ File not found!")
        print("Available resources: \(Bundle.main.paths(forResourcesOfType: "json", inDirectory: nil))")
        throw ImportError.fileNotFound
    }

    print("✅ Found file at: \(url)")

    let data = try Data(contentsOf: url)
    print("📦 Data size: \(data.count) bytes")

    let legacySongs = try JSONDecoder().decode([LegacySongJSON].self, from: data)
    print("📝 Decoded \(legacySongs.count) songs")

    // ... rest of import code ...

    print("✅ Import complete!")
}
```

## Checking Database Contents

### View in Xcode Debugger

```swift
// Add breakpoint and in console:
po allSongs.count
po allSongs.map { $0.name }
```

### Add Debug View

```swift
struct DebugView: View {
    @Query private var songs: [Song]
    @Query private var artists: [Artist]
    @Query private var albums: [Album]

    var body: some View {
        List {
            Section("Songs (\(songs.count))") {
                ForEach(songs) { song in
                    Text(song.name)
                }
            }
            Section("Artists (\(artists.count))") {
                ForEach(artists) { artist in
                    Text(artist.name)
                }
            }
            Section("Albums (\(albums.count))") {
                ForEach(albums) { album in
                    Text(album.name)
                }
            }
        }
    }
}
```

## Getting Help

1. **Check Console** - Most errors are logged there
2. **Read Migration Guide** - See `MIGRATION_GUIDE.md`
3. **Check Examples** - See `AdvancedQueryExamples.swift`
4. **Review Models** - Understand relationships in `Song.swift`

## Clean Build

Sometimes Xcode needs a clean slate:

1. Product → Clean Build Folder (`Cmd+Shift+K`)
2. Delete Derived Data:
   - Xcode → Settings → Locations
   - Click arrow next to Derived Data path
   - Delete your project's folder
3. Restart Xcode
4. Build again

## Still Having Issues?

Create a minimal test:

```swift
struct TestImportView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 20) {
            Button("Test Import") {
                Task {
                    do {
                        let service = DataImportService()
                        try await service.importLegacyJSON(from: "songs", into: modelContext)
                        print("✅ Import succeeded")
                    } catch {
                        print("❌ Import failed: \(error)")
                    }
                }
            }

            Button("Check Count") {
                let descriptor = FetchDescriptor<Song>()
                let count = (try? modelContext.fetchCount(descriptor)) ?? 0
                print("📊 Song count: \(count)")
            }
        }
        .padding()
    }
}
```

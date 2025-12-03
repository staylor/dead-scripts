# Dead Sheets - Architecture Overview

A multi-platform music lead sheet viewer for iOS, macOS, watchOS, tvOS, and CarPlay with cross-device synchronization and Apple Music integration.

## Project Structure

```
leadsheets/
├── LeadSheetsApp.swift              # App entry point, SwiftData container
├── CarPlaySceneDelegate.swift       # CarPlay interface
│
├── Models/
│   ├── Song.swift                   # Core entity with PDF/lyrics
│   ├── Album.swift                  # Album with cover art
│   ├── Artist.swift                 # Band/performer
│   ├── Singer.swift                 # Member who sang song
│   ├── Writer.swift                 # Songwriter with contribution type
│   └── GroupedWriter.swift          # Helper for grouped writer display
│
├── Views/
│   ├── ContentView.swift            # Platform-aware view router
│   ├── SearchScreen.swift           # Multi-filter search and list
│   ├── PDFViewerScreen.swift        # Lead sheet PDF display
│   ├── ImageViewerScreen.swift      # tvOS image viewer
│   ├── LyricsInspector.swift        # macOS sidebar lyrics
│   ├── LyricsOverlay.swift          # Draggable lyrics modal (iOS)
│   ├── SettingsView.swift           # Sync preferences
│   ├── FilteredSongsView.swift      # Song list with filtering
│   ├── EmptyStateView.swift         # No data placeholder
│   ├── PlatformListView.swift       # Platform-specific list styling
│   ├── *ListView.swift              # List containers (Albums, Artists, etc.)
│   └── *RowView.swift               # Row components (Song, Album, Artist, etc.)
│
├── Services/
│   ├── DataImportService.swift      # JSON decoding and model creation
│   ├── DataImportManager.swift      # Import orchestration, hash-based change detection
│   ├── CloudSyncManager.swift       # CloudKit sync (iPhone/iPad/Mac)
│   ├── WatchConnectivityManager.swift # iPhone-Watch direct sync
│   ├── MusicPlayerService.swift     # Apple Music/MusicKit playback
│   └── ImageLoader.swift            # Image loading with caching
│
├── Utilities/
│   ├── PDFKitView.swift             # Base PDFKit wrapper
│   ├── PDFKitView+iOS.swift         # iOS PDF implementation
│   ├── PDFKitView+macOS.swift       # macOS PDF implementation
│   ├── PlatformColors.swift         # Cross-platform color definitions
│   ├── CachedImage.swift            # Cached image view component
│   ├── RowContainer.swift           # Reusable row layout container
│   ├── ResizeHandle.swift           # Draggable resize control
│   └── ImportManagerModifier.swift  # SwiftUI modifier for imports
│
├── Resources/
│   ├── Assets.xcassets              # App icons, colors, images
│   ├── seeds.json                   # Song database (~500 songs)
│   ├── pdfs/                        # Lead sheet PDFs
│   ├── images/                      # Album/artist images
│   ├── albums/                      # Album cover art
│   └── artists/                     # Artist photos
│
└── leadsheets.watch/                # watchOS app target
    ├── LeadSheetsWatchApp.swift
    ├── ContentView.swift
    └── LyricsDetailView.swift
```

## Data Models

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           SwiftData Models                               │
└─────────────────────────────────────────────────────────────────────────┘

    ┌──────────┐           ┌──────────┐           ┌──────────┐
    │  Artist  │──albums──▶│  Album   │◀──album───│   Song   │
    │          │           │          │           │          │
    │ id       │◀──artist──│ id       │           │ id       │
    │ name     │           │ name     │           │ name     │
    │ image    │           │ slug     │           │ slug     │
    └────┬─────┘           │ coverArt │           │ fileName │
         │                 │ year     │           │ lyrics   │
         │                 └──────────┘           │ track#   │
         │                                        │ disc#    │
         │ songs                                  │ songType │
         ▼                                        │ appleId  │
    ┌──────────┐                                  └────┬─────┘
    │   Song   │◀─────────────────────────────────────┘
    └────┬─────┘
         │
    ┌────┴─────────────────────────┐
    │                              │
    ▼                              ▼
┌──────────┐                 ┌──────────┐
│  Singer  │                 │  Writer  │
│          │                 │          │
│ id       │                 │ id       │
│ name     │                 │ name     │
│ image    │                 │ contrib  │ ← "music", "lyrics", etc.
│ songs    │                 │ image    │
└──────────┘                 │ songs    │
                             └──────────┘
```

**Key Model Features:**

- All models use `@Attribute(.unique)` on `id` for uniqueness
- Songs can have multiple Writers (many-to-many)
- Singer represents the original artist (for cover songs)
- Artist represents the performing band
- GroupedWriter is a non-persisted helper for UI grouping
- Song has computed properties: `pdfURL`, `imageURL` (tvOS), `writersDisplayText`, `singerDisplayText`
- Album has `sortedSongs` computed property (by disc/track number)

## App Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              App Launch                                  │
└─────────────────────────────────────────────────────────────────────────┘

                           LeadSheetsApp
                                 │
                   .modelContainer(for: [Song, Album, Artist, Singer, Writer])
                                 │
                                 ▼
                           ContentView
                                 │
            ┌────────────────────┼────────────────────┐
            │                    │                    │
       First Launch         Hash Changed        Normal Launch
            │                    │                    │
            ▼                    ▼                    ▼
    ┌───────────────┐   ┌───────────────┐   ┌───────────────┐
    │ Import JSON   │   │ Re-import     │   │ Query DB      │
    │ Save to DB    │   │ (atomic)      │   │ Show results  │
    │ Store hash    │   │ Update hash   │   │ (instant!)    │
    └───────────────┘   └───────────────┘   └───────────────┘
```

**Import Process:**

1. DataImportManager computes SHA256 hash of seeds.json
2. Compares against stored hash in AppStorage
3. If changed: clears existing data, imports fresh
4. DataImportService (actor for thread safety) decodes JSON, creates SwiftData models
5. Models inserted via ModelContext batch operations
6. Posts `.songsDidImport` notification for CarPlay refresh

## Search & Filter Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Multi-Filter System                             │
└─────────────────────────────────────────────────────────────────────────┘

    enum SearchFilter {
        case allSongs      → Show all songs alphabetically
        case byAlbum       → Group by album, show album covers
        case byArtist      → Group by artist
        case bySinger      → Group by original singer (covers)
        case byWriter      → Group by songwriter(s)
        case covers        → Filter to cover songs only
    }

                    SearchScreen
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
    Filter Tabs     Search Bar      Results List
        │                │                │
        └────────────────┴────────────────┘
                         │
                         ▼
                  Filtered Results
                  (in-memory filter)
```

**Search Implementation:**

- @Query fetches all songs from SwiftData
- In-memory filtering by name, artist, album, lyrics, singer, writer
- Filter enum controls list presentation and grouping
- GroupedWriter helper combines writers with same contribution on same songs

## Platform Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Multi-Platform Design                            │
└─────────────────────────────────────────────────────────────────────────┘

    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
    │       iOS       │    │      macOS      │    │      tvOS       │
    ├─────────────────┤    ├─────────────────┤    ├─────────────────┤
    │ Full-screen PDF │    │ 3-column split  │    │ Image viewer    │
    │ Lyrics overlay  │    │ Songs|PDF|Lyrics│    │ Focus navigation│
    │ CarPlay support │    │ Inspector panel │    │ No PDF support  │
    │ CloudKit sync   │    │ CloudKit sync   │    │ Zoom controls   │
    │ Watch pairing   │    │ MusicKit play   │    │                 │
    │ MusicKit play   │    │                 │    │                 │
    └─────────────────┘    └─────────────────┘    └─────────────────┘

    ┌─────────────────┐    ┌─────────────────┐
    │     watchOS     │    │     CarPlay     │
    ├─────────────────┤    ├─────────────────┤
    │ Song list       │    │ Alphabetical    │
    │ Lyrics detail   │    │   song list     │
    │ iPhone sync     │    │ Apple Music     │
    └─────────────────┘    │   playback      │
                           │ Shared DB       │
                           └─────────────────┘
```

**Platform Separation:**

- Conditional compilation: `#if os(iOS)`, `#if os(macOS)`, etc.
- Platform-specific file extensions: `PDFKitView+iOS.swift`
- Shared models across all platforms
- PlatformColors/PlatformListView for styling abstraction

## Cross-Device Sync

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Sync Architecture                                │
└─────────────────────────────────────────────────────────────────────────┘

                              CloudKit
                           (Private DB)
                                 │
              ┌──────────────────┼──────────────────┐
              │                  │                  │
              ▼                  ▼                  ▼
         ┌────────┐         ┌────────┐         ┌────────┐
         │ iPhone │         │  iPad  │         │  Mac   │
         └───┬────┘         └────────┘         └────────┘
             │
    WatchConnectivity
             │
             ▼
         ┌────────┐
         │ Watch  │
         └────────┘
```

**CloudSyncManager:**

- Uses CloudKit private database
- Syncs selected song slug across iPhone, iPad, Mac
- Polls CloudKit every 5 seconds when enabled
- Stores device type (phone/pad/mac) for tracking
- Prevents echoing selection back to sender device
- Forwards selections to Watch via WatchConnectivityManager
- @ObservedObject singleton with published properties

**WatchConnectivityManager:**

- Direct iPhone ↔ Watch communication via WCSession
- Immediate updates without cloud latency
- Works offline (paired devices)
- Syncs currently selected song for lyrics display
- Uses both direct messages and application context

**MusicPlayerService:**

- Singleton wrapper around MusicKit
- Plays songs via Apple Music catalog lookup using appleMusicId
- Publishes: isPlaying, isLoading, currentSongId, authorizationStatus
- Fallback to URL deep-link if MusicKit unavailable
- Per-song loading/playing state tracking
- Cross-platform (iOS/macOS)

## State Management

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         State Hierarchy                                  │
└─────────────────────────────────────────────────────────────────────────┘

    @main LeadSheetsApp
        │
        │ .modelContainer (app-level)
        │
        ├─→ ContentView
        │       │
        │       │ @Environment(\.modelContext)
        │       │ @Query var songs: [Song]
        │       │ @State var searchText
        │       │ @State var selectedSong
        │       │ @State var searchFilter
        │       │ @AppStorage("syncEnabled")
        │       │ @StateObject cloudSyncManager
        │       │ @StateObject watchManager
        │       │
        │       ├─→ SearchScreen
        │       │       @Binding searchText
        │       │       @Binding searchFilter
        │       │       songs: [Song]
        │       │
        │       └─→ PDFViewerScreen
        │               song: Song
        │               @State showLyrics
        │               │
        │               └─→ LyricsOverlay
        │                       song: Song
        │                       @Binding isShowing
        │                       @State position/size
```

**State Patterns:**

- @Environment for ModelContext injection
- @Query for automatic SwiftData binding
- @State for local UI state
- @StateObject for singleton managers
- @AppStorage for user preferences
- @Binding for parent-child communication

## Performance Considerations

**SwiftData Advantages:**

- Lazy loading: only visible songs in memory
- Database indexes for fast search
- Automatic change observation via @Query
- Batch operations for imports

**Memory Management:**

- ~500 songs with lazy loading uses ~5MB vs ~50MB if all in memory
- PDFs loaded on-demand, not preloaded
- Images loaded via ImageLoader with caching

**Import Optimization:**

- SHA256 hash check prevents unnecessary re-imports
- Atomic clear-and-reimport for data consistency
- Batch inserts via ModelContext

## Extension Points

**Adding New Features:**

```swift
// 1. Favorites - add property to Song
@Model class Song {
    var isFavorite: Bool = false
}

// 2. Playlists - new model
@Model class Playlist {
    var name: String
    var songs: [Song]
}

// 3. Play history - add tracking
@Model class Song {
    var playCount: Int = 0
    var lastPlayed: Date?
}

// 4. Full CloudKit sync - modify container
.modelContainer(for: [...], cloudKitDatabase: .private("iCloud.com.app"))
```

## Key Files Reference

| File                                | Purpose                              |
| ----------------------------------- | ------------------------------------ |
| `LeadSheetsApp.swift`               | App entry, SwiftData container setup |
| `Views/ContentView.swift`           | Platform-aware view router           |
| `Models/Song.swift`                 | Core data model with relationships   |
| `Services/DataImportService.swift`  | JSON → SwiftData conversion (actor)  |
| `Services/DataImportManager.swift`  | Import orchestration, hash detection |
| `Services/CloudSyncManager.swift`   | Cross-device CloudKit sync           |
| `Services/WatchConnectivityManager.swift` | iPhone-Watch direct sync       |
| `Services/MusicPlayerService.swift` | MusicKit/Apple Music playback        |
| `Views/SearchScreen.swift`          | Main search/filter interface         |
| `Views/PDFViewerScreen.swift`       | Lead sheet PDF viewer                |
| `Views/ImageViewerScreen.swift`     | tvOS image viewer with zoom          |
| `Views/LyricsInspector.swift`       | macOS sidebar lyrics panel           |
| `Views/LyricsOverlay.swift`         | iOS draggable lyrics modal           |
| `Utilities/PDFKitView+iOS/macOS.swift` | Platform-specific PDF rendering   |
| `CarPlaySceneDelegate.swift`        | CarPlay interface                    |

## Technology Stack

- **UI**: SwiftUI
- **Persistence**: SwiftData (SQLite)
- **Cloud**: CloudKit (private database)
- **Watch**: WatchConnectivity
- **PDF**: PDFKit (iOS/macOS only)
- **Music**: MusicKit (Apple Music integration)
- **CarPlay**: CarPlay framework (CPTemplateApplicationSceneDelegate)
- **Hashing**: CryptoKit (SHA256)
- **Reactive**: Combine, @Observable, @ObservedObject

## CarPlay Integration

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          CarPlay Architecture                            │
└─────────────────────────────────────────────────────────────────────────┘

    CarPlaySceneDelegate
           │
           ├─→ SharedModelContainer.shared (same as main app)
           │
           ├─→ CPListTemplate (alphabetical song groups)
           │       │
           │       └─→ CPListSection per letter (A-Z, #)
           │               │
           │               └─→ CPListItem per song
           │
           ├─→ MusicPlayerService.shared
           │       │
           │       └─→ Apple Music playback
           │
           └─→ CPNowPlayingTemplate (pushed on play)
```

**CarPlay Features:**

- Songs grouped alphabetically (# for numbers/symbols)
- Tapping song starts Apple Music playback
- Uses shared ModelContainer with main app
- Listens for `.songsDidImport` to refresh list
- Requests MusicKit authorization on connect

## Platform Comparison

| Feature          | iOS                      | macOS              | tvOS              | watchOS         | CarPlay      |
|------------------|--------------------------|-------------------|-------------------|-----------------|-------------|
| PDF Viewer       | Full-screen PDFKit       | 3-col split       | N/A (PNG images)  | N/A             | N/A         |
| Lyrics Display   | Draggable overlay        | Inspector panel   | Side panel        | ScrollView      | N/A         |
| Navigation       | NavigationStack          | NavigationSplit   | Conditional       | NavigationStack | CPListTemp  |
| Sync             | CloudKit + Watch         | CloudKit          | None              | WatchConnect    | Shared DB   |
| Music Playback   | MusicKit                 | MusicKit          | None              | None            | MusicKit    |
| Image Zoom       | Locked to width          | 4x max zoom       | Manual buttons    | N/A             | N/A         |
| Search           | Text + filter pills      | Text + grid       | Segmented picker  | List browse     | N/A         |

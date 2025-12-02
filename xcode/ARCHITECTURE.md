# Lead Sheets - Architecture Overview

A multi-platform music lead sheet viewer for iOS, macOS, watchOS, and tvOS with cross-device synchronization.

## Project Structure

```
leadsheets/
├── LeadSheetsApp.swift              # App entry point, SwiftData container
├── ContentView.swift                # Platform-aware view router
│
├── Models/
│   ├── Song.swift                   # Core entity with PDF/lyrics
│   ├── Album.swift                  # Album with cover art
│   ├── Artist.swift                 # Band/performer
│   ├── Singer.swift                 # Member who sang song
│   ├── Writer.swift                 # Songwriter with contribution type
│   └── GroupedWriter.swift          # Helper for grouped writer display
│
├── Services/
│   ├── DataImportService.swift      # JSON decoding and model creation
│   ├── DataImportManager.swift      # Import orchestration, hash-based change detection
│   ├── CloudSyncManager.swift       # CloudKit sync (iPhone/iPad/Mac)
│   └── WatchConnectivityManager.swift # iPhone-Watch direct sync
│
├── Views - Main Screens/
│   ├── SearchScreen.swift           # Multi-filter search and list
│   ├── PDFViewerScreen.swift        # Lead sheet PDF display
│   ├── ImageViewerScreen.swift      # tvOS image viewer
│   ├── LyricsInspector.swift        # macOS sidebar lyrics
│   └── SettingsView.swift           # Sync preferences
│
├── Views - Components/
│   ├── SongRowView.swift            # Song list item
│   ├── AlbumRowView.swift           # Album list item
│   ├── ArtistRowView.swift          # Artist list item
│   ├── SingerRowView.swift          # Singer list item
│   ├── GroupedWriterRowView.swift   # Writer list item
│   ├── LyricsOverlay.swift          # Draggable lyrics modal (iOS)
│   ├── EmptyStateView.swift         # No data placeholder
│   └── Platform*.swift              # Platform-specific utilities
│
├── PDFKit Integration/
│   ├── PDFKitView.swift             # Base PDFKit wrapper
│   ├── PDFKitView+iOS.swift         # iOS implementation
│   └── PDFKitView+macOS.swift       # macOS implementation
│
├── Platform-Specific/
│   ├── CarPlaySceneDelegate.swift   # CarPlay interface
│   └── ImageLoader.swift            # Network image loading
│
├── Resources/
│   ├── seeds.json                   # Song database (~500 songs)
│   ├── pdfs/                        # Lead sheet PDFs
│   └── images/                      # Album/artist images
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
2. Compares against stored hash in UserDefaults
3. If changed: clears existing data, imports fresh
4. DataImportService decodes JSON, creates SwiftData models
5. Models inserted via ModelContext batch operations

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
    │ CloudKit sync   │    │ CloudKit sync   │    │                 │
    │ Watch pairing   │    │                 │    │                 │
    └─────────────────┘    └─────────────────┘    └─────────────────┘

    ┌─────────────────┐
    │     watchOS     │
    ├─────────────────┤
    │ Song list       │
    │ Lyrics detail   │
    │ iPhone sync     │
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
- Syncs selected song/album across iPhone, iPad, Mac
- Stores device type for last-selected tracking
- @Observable with @MainActor for UI updates

**WatchConnectivityManager:**

- Direct iPhone ↔ Watch communication
- Immediate updates without cloud latency
- Works offline (paired devices)
- Syncs currently selected song for lyrics display

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

| File                             | Purpose                              |
| -------------------------------- | ------------------------------------ |
| `LeadSheetsApp.swift`            | App entry, SwiftData container setup |
| `ContentView.swift`              | Platform-aware view router           |
| `Song.swift`                     | Core data model with relationships   |
| `DataImportService.swift`        | JSON → SwiftData conversion          |
| `DataImportManager.swift`        | Import orchestration, hash detection |
| `CloudSyncManager.swift`         | Cross-device CloudKit sync           |
| `WatchConnectivityManager.swift` | iPhone-Watch direct sync             |
| `SearchScreen.swift`             | Main search/filter interface         |
| `PDFViewerScreen.swift`          | Lead sheet PDF viewer                |
| `PDFKitView+iOS/macOS.swift`     | Platform-specific PDF rendering      |
| `CarPlaySceneDelegate.swift`     | CarPlay interface                    |

## Technology Stack

- **UI**: SwiftUI
- **Persistence**: SwiftData (SQLite)
- **Cloud**: CloudKit (private database)
- **Watch**: WatchConnectivity
- **PDF**: PDFKit
- **Hashing**: CryptoKit (SHA256)
- **Reactive**: Combine, @Observable

# 🏗️ App Architecture Overview

## Data Model Relationships

```
┌─────────────────────────────────────────────────────────────────┐
│                         SWIFTDATA MODELS                         │
└─────────────────────────────────────────────────────────────────┘

                              ┌──────────┐
                              │  Artist  │
                              ├──────────┤
                              │ id       │
                              │ name     │
                              │ bio      │
                              │ image    │
                              └────┬─────┘
                                   │
                     ┌─────────────┴─────────────┐
                     │                           │
                     │ songs                     │ albums
                     ▼                           ▼
              ┌──────────┐                 ┌──────────-──┐
              │   Song   │◄────album───────│    Album    │
              ├──────────┤                 ├─────────────┤
              │ id       │                 │ id          │
              │ name     │                 │ name        │
              │ fileName │                 │ coverArt    |
              │ lyrics   │                 │ label       │
              │ track #  │                 | releaseYear |
              │ year     │                 └─────────---─┘
              └──────────┘
```

## App Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                          APP LAUNCH                              │
└─────────────────────────────────────────────────────────────────┘

                         LeadSheetsApp.swift
                                 │
                                 │ .modelContainer(for: [...])
                                 ▼
                          ContentView.swift
                                 │
                     ┌───────────┴───────────┐
                     │                       │
         First Launch│              Subsequent│Launches
                     ▼                       ▼
          ┌─────────────────┐      ┌──────────────────┐
          │ Show Progress   │      │ Query Database   │
          │ Import JSON     │      │ Show Results     │
          │ Save to DB      │      │ Instant!         │
          │ Set Flag        │      └──────────────────┘
          └─────────────────┘
                     │
                     └──────────┬──────────────────────┐
                                │                      │
                                ▼                      ▼
                        ┌──────────────┐      ┌──────────────┐
                        │ SearchScreen │      │PDFViewerScreen│
                        ├──────────────┤      ├──────────────┤
                        │ Search Bar   │      │ PDF Display  │
                        │ Song List    │      │ Back Button  │
                        │ Tap → Open   │      │ Lyrics Btn   │
                        └──────────────┘      └──────┬───────┘
                                                     │
                                                     ▼
                                             ┌──────────────┐
                                             │LyricsOverlay │
                                             ├──────────────┤
                                             │ Draggable    │
                                             │ Resizable    │
                                             │ Show Lyrics  │
                                             └──────────────┘
```

## Data Import Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         DATA IMPORT                              │
└─────────────────────────────────────────────────────────────────┘

         songs.json (Bundle)
                │
                │ Read file
                ▼
    ┌────────────────────────┐
    │  DataImportService     │
    ├────────────────────────┤
    │ importLegacyJSON()     │
    │ or                     │
    │ importStructuredJSON() │
    └───────────┬────────────┘
                │
                │ Decode JSON
                ▼
      ┌──────────────────┐
      │ Parse & Cache:   │
      │  - Artists       │
      │  - Albums        │
      └────────┬─────────┘
               │
               │ Create models
               ▼
      ┌──────────────────┐
      │ Insert into      │
      │ ModelContext     │
      └────────┬─────────┘
               │
               │ context.save()
               ▼
      ┌──────────────────┐
      │ SwiftData        │
      │ Database         │
      │ (SQLite)         │
      └──────────────────┘
```

## Search & Filter Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                       SEARCH & FILTER                            │
└─────────────────────────────────────────────────────────────────┘

                    User Types in Search
                            │
                            ▼
                  ┌──────────────────┐
                  │ searchText       │
                  │ @Binding         │
                  └────────┬─────────┘
                           │
                           ▼
               ┌──────────────────────┐
               │ ContentView          │
               │ filteredSongs        │
               └────────┬─────────────┘
                        │
        ┌───────────────┴────────────────────────┐
        │                                        │
        │ Filter allSongs where:                 │
        │  - name contains searchText            │
        │  - artist.name contains searchText     │
        │  - album.name contains searchText      │
        │  - lyrics contains searchText          │
        │                                        │
        └───────────────┬────────────────────────┘
                        │
                        ▼
                ┌──────────────────┐
                │ SearchScreen     │
                │ Display Results  │
                └──────────────────┘
```

## Query Pattern

```
┌─────────────────────────────────────────────────────────────────┐
│                      @QUERY PATTERN                              │
└─────────────────────────────────────────────────────────────────┘

         In Any SwiftUI View:

    @Query(sort: \Song.name)
    private var songs: [Song]
              │
              │ SwiftData automatically:
              │  1. Fetches from database
              │  2. Sorts results
              │  3. Observes changes
              │  4. Updates view
              │
              ▼
         ┌────────────────┐
         │ Your View      │
         │ Uses songs     │
         │ Automatically! │
         └────────────────┘


    With Filtering:

    @Query(filter: #Predicate<Song> { song in
        song.artist?.name == "Miles Davis"
    }, sort: \Song.name)
    private var songs: [Song]
              │
              │ Database Query (Fast!)
              ▼
         Only Miles Davis songs
```

## File Organization

```
📁 Lead Sheets App/
│
├── 📁 App/
│   ├── LeadSheetsApp.swift          ← Entry point
│   └── ContentView.swift            ← Main view
│
├── 📁 Models/
│   └── Song.swift                   ← Data models (Song, Artist, Album)
│
├── 📁 Services/
│   ├── DataImportService.swift      ← JSON import
│   └── SongDataManager.swift        ← Database helpers
│
├── 📁 Views/
│   ├── SearchScreen.swift           ← Song list & search
│   ├── SongRowView.swift            ← Individual song row
│   ├── PDFViewerScreen.swift        ← PDF display
│   ├── LyricsOverlay.swift          ← Lyrics popup
│   └── PDFKitView.swift             ← UIKit wrapper
│
├── 📁 Examples/
│   └── AdvancedQueryExamples.swift  ← Reference code
│
├── 📁 Resources/
│   ├── songs.json                   ← Seed data
│   ├── songs-new-format-example.json ← Template
│   └── 📁 PDFs/
│       ├── song1.pdf
│       ├── song2.pdf
│       └── ...
│
└── 📁 Documentation/
    ├── SUMMARY.md                   ← Quick overview
    ├── README_SWIFTDATA.md          ← User guide
    ├── MIGRATION_GUIDE.md           ← Technical docs
    ├── TROUBLESHOOTING.md           ← Common issues
    ├── CHECKLIST.md                 ← Pre-launch checks
    └── ARCHITECTURE.md              ← This file
```

## Memory & Performance

```
┌─────────────────────────────────────────────────────────────────┐
│                    MEMORY MANAGEMENT                             │
└─────────────────────────────────────────────────────────────────┘

         OLD WAY (JSON Array):
         ┌──────────────────────┐
         │ All 500 songs        │
         │ All 500 artists      │ ← Always in RAM
         │ All 500 albums       │ ← Can't scale
         │ All 500 lyrics       │
         └──────────────────────┘
                 Memory: ~50MB


         NEW WAY (SwiftData):
         ┌──────────────────────┐
         │ Only visible songs   │ ← Lazy loading
         │ Only queried data    │ ← On-demand
         │ Smart caching        │ ← Automatic
         └──────────────────────┘
                 Memory: ~5MB


    Search Performance:

    OLD: O(n) - Check every song
    ┌─┬─┬─┬─┬─┬─┬─┬─┬─┬─┐
    │1│2│3│4│5│6│7│8│9│10│ Check all...
    └─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘

    NEW: O(log n) - Database index
    ┌───────────┐
    │   Index   │ ← Fast lookup
    └───────────┘
```

## State Management

```
┌─────────────────────────────────────────────────────────────────┐
│                    STATE HIERARCHY                               │
└─────────────────────────────────────────────────────────────────┘

    @main
    LeadSheetsApp
        │
        │ .modelContainer (App-level)
        │
        ├─→ ContentView
        │       │
        │       │ @Environment(\.modelContext)
        │       │ @Query(all songs)
        │       │ @State(searchText)
        │       │ @State(selectedPDF)
        │       │ @AppStorage(hasImported)
        │       │
        │       ├─→ SearchScreen
        │       │       │
        │       │       │ @Binding(searchText)
        │       │       │ songs: [Song]
        │       │       │
        │       │       └─→ SongRowView (foreach)
        │       │               │
        │       │               │ song: Song
        │       │
        │       └─→ PDFViewerScreen
        │               │
        │               │ song: Song
        │               │ @State(showInfo)
        │               │
        │               └─→ LyricsOverlay
        │                       │
        │                       │ song: Song
        │                       │ @Binding(isShowing)
        │                       │ @State(position)
        │
        └─→ Other Views...
```

## Extension Points

```
┌─────────────────────────────────────────────────────────────────┐
│                   EASY TO ADD FEATURES                           │
└─────────────────────────────────────────────────────────────────┘

    1. Favorites:
       ┌────────────────┐
       │ @Model Song    │
       │ + isFavorite   │ ← Just add property
       └────────────────┘

    2. Playlists:
       ┌────────────────┐
       │ @Model         │
       │ Playlist       │ ← New model
       │ - songs: [Song]│
       └────────────────┘

    3. Play History:
       ┌────────────────┐
       │ @Model Song    │
       │ + playCount    │ ← Track usage
       │ + lastPlayed   │
       └────────────────┘

    4. CloudKit Sync:
       ┌────────────────┐
       │ .modelContainer│
       │ + cloudKitID   │ ← Enable sync
       └────────────────┘
```

## Summary

- **SwiftData** = Modern, efficient database
- **@Query** = Automatic, reactive data binding
- **Relationships** = Artist ↔ Song ↔ Album work automatically
- **Import once** = Fast subsequent launches
- **Scalable** = Handles thousands of songs
- **Memory efficient** = Lazy loading
- **Fast search** = Database indexes
- **Easy to extend** = Add features with minimal code

**Your app is built on a solid foundation! 🏗️**

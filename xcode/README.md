# Dead Sheets

Grateful Dead lead sheets and lyrics for iPhone, iPad, Mac, Apple TV, Apple Watch and CarPlay. Browse by song, album, artist, singer or writer, put songs in setlists, and step through them on stage with the toolbar or a page-turner pedal. Songs play from Apple Music, and the open song can follow you to your other devices.

| Platform | What it shows |
| --- | --- |
| iPhone | The library, then the lead sheet, with lyrics in a sheet |
| iPad, Mac | The library beside the lead sheet, with lyrics in an inspector |
| Apple TV | A tab per category; sheets are PNGs because tvOS has no PDFKit |
| Apple Watch | Lyrics, following the song open on the iPhone |
| CarPlay | Songs and albums, played through Apple Music |

## Building

Requirements: Xcode 26.3 or later.

1. Open `leadsheets.xcodeproj`. The `leadsheets` scheme builds the iPhone, iPad, Mac and Apple TV app, and embeds the watch app in iOS builds.
2. Choose a run destination and run. Signing uses team `LQR2VDPY65`.

The catalog (`DeadSheetsKit/Sources/DeadSheetsKit/Resources/seeds.json`), album covers and band photos are in the repository. The lead sheets themselves aren't, so a fresh clone builds and runs with a "Lead Sheet Missing" placeholder until you generate them.

## Generating the data

The scripts in the repository root produce everything under `xcode/` from the Prisma database and the score PDFs in iCloud Drive:

```sh
yarn apple-music   # look up Apple Music IDs, and download 600 px covers and photos
yarn xcode         # write seeds.json, copy the score PDFs, and render them for tvOS
```

`yarn xcode` writes:

- `DeadSheetsKit/Sources/DeadSheetsKit/Resources/seeds.json`: the catalog.
- `Sheets/pdfs/`: one `<Title> Score.pdf` per song, bundled for iOS and macOS.
- `Sheets/images/`: the same sheets as 3x PNGs (via `convert_pdfs.swift`), bundled for tvOS.

`Sheets/` is ignored by Git apart from the `.gitkeep` files.

## Testing

```sh
swift test --package-path DeadSheetsKit                     # catalog, grouping, search and seed integrity
xcodebuild test -project leadsheets.xcodeproj -scheme leadsheets \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'   # UI tests
swift format lint --recursive --strict .                     # formatting
```

The seed-integrity tests check that every song in `seeds.json` resolves its singer and writers and has lyrics, and that every cover and photo exists. Once `Sheets/` has been generated, they also check for a PDF and a tvOS image for every song.

UI tests launch the app with `-inMemoryUserData`, so favorites and setlists start empty each time.

CI (`.github/workflows/xcode.yml`) builds macOS, iOS + watchOS and tvOS, and runs the package tests, the UI tests and the format check, on every change under `xcode/`.

## Releasing

- Bump the version with `xcrun agvtool new-marketing-version 1.1` and the build with `xcrun agvtool next-version -all`.
- Before the first TestFlight build, deploy the `SongSelection` record type to Production in the CloudKit Console. Production builds can't create it.
- In App Store Connect, set App Privacy to "Data Not Collected", and use [`PRIVACY.md`](PRIVACY.md) as the privacy policy URL.
- CarPlay needs the CarPlay audio entitlement on the App ID and provisioning profile.

See [`ARCHITECTURE.md`](ARCHITECTURE.md) for how the code fits together.

# Dead Sheets

Grateful Dead lead sheets and lyrics for iPhone, iPad, Mac, Apple TV, Apple Watch and CarPlay. Browse by song, album, artist, singer or writer, put songs in setlists, and step through them on stage with the toolbar or a page-turner pedal. Songs play from Apple Music, and the open song can follow you to your other devices.

| Platform | What it shows |
| --- | --- |
| iPhone | The library, then the lead sheet, with lyrics in a sheet |
| iPad, Mac | The library beside the lead sheet, with lyrics in an inspector |
| Apple TV | A tab per category; the lead sheet beside its lyrics, zoomed with the remote |
| Apple Watch | Lyrics, following the song open on the iPhone |
| CarPlay | Songs and albums, played through Apple Music |

## Building

Requirements: Xcode 27.1 or later.

1. Open `leadsheets.xcodeproj`. The `leadsheets` scheme builds the iPhone, iPad, Mac and Apple TV app, and embeds the watch app in iOS builds.
2. Choose a run destination and run. Signing uses team `LQR2VDPY65`.

Everything the app bundles is in the repository: the catalog (`DeadSheetsKit/Sources/DeadSheetsKit/Resources/seeds.json`), the lead sheets and their tvOS images (`Sheets/`), album covers and band photos. A fresh clone builds the complete app, and so does CI.

## Generating the data

The scripts in the repository root generate the data from the Prisma database and the scores in iCloud Drive. Their output is committed, so they only need to run on a machine with both, after something changes:

```sh
pnpm apple-music   # look up Apple Music IDs, and download 600 px covers and photos
pnpm xcode         # write seeds.json, and update the lead sheets from iCloud Drive
```

`pnpm xcode` writes:

- `DeadSheetsKit/Sources/DeadSheetsKit/Resources/seeds.json`: the catalog.
- `Sheets/pdfs/`: each song's score, named after its `fileName` in the catalog, bundled for iOS and macOS.
- `Sheets/images/`: the same sheets as 3x PNGs (via `convert_pdfs.swift`), bundled for tvOS.

`Sheets/schema.json` says where each song's score lives in the iCloud Drive scores folder, keyed by song slug. A new song needs an entry there, or `pnpm xcode` stops before writing anything. The script only rewrites PDFs whose content changed, renders tvOS images only for those, and removes sheets for songs that left the catalog. Commit whatever changes under `Sheets/`.

## Testing

```sh
swift test --package-path DeadSheetsKit                     # catalog, grouping, search and seed integrity
xcodebuild test -project leadsheets.xcodeproj -scheme leadsheets \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro'   # UI tests
swift format lint --recursive --strict .                     # formatting
```

The seed-integrity tests check that every song in `seeds.json` resolves its singer and writers and has lyrics, and that every cover and photo exists. They also check that `Sheets/schema.json` covers exactly the catalog's songs, and that `Sheets/` has a PDF and a tvOS image for every song, and nothing else.

UI tests launch the app with `-inMemoryUserData`, so favorites and setlists start empty each time.

CI (`.github/workflows/xcode.yml`) builds macOS, iOS + watchOS and tvOS with Xcode 27.1, and runs the package tests, the UI tests and the format check, on every change under `xcode/`. On `main`, it then uploads the apps to TestFlight.

## Releasing

Every merge to `main` that changes `xcode/` uploads TestFlight builds for iOS (with the watch app), macOS and tvOS once CI passes. To upload without a change, for example when the 90-day builds expire, run the Xcode workflow from the Actions tab.

- The `testflight` environment, which only deploys from `main`, holds an App Store Connect team key with the Admin role: `ASC_KEY` (the contents of the `.p8`), `ASC_KEY_ID` and `ASC_ISSUER_ID`.
- Archives are signed for development, which needs a registered device for each platform. CI has its own development certificate, `DEVELOPMENT_CERTIFICATE` (a base64 `.p12`) and `DEVELOPMENT_CERTIFICATE_PASSWORD`, which expires on 2027-10-26. To replace it, export a new Apple Development certificate as a `.p12` (Xcode → Settings → Accounts → Manage Certificates) and update both secrets. Until then, each job creates a certificate of its own.
- Uploads are signed with cloud-managed distribution certificates, and Xcode gives each one the next build number for its platform (`ExportOptions.plist`), so only the version needs bumping: `xcrun agvtool new-marketing-version 1.1`.
- Before the first TestFlight build, deploy the `SongSelection` record type to Production in the CloudKit Console. Production builds can't create it.
- In App Store Connect, set App Privacy to "Data Not Collected", and use [`PRIVACY.md`](PRIVACY.md) as the privacy policy URL.

See [`ARCHITECTURE.md`](ARCHITECTURE.md) for how the code fits together.

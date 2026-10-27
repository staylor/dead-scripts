# CLAUDE.md

Guidance for coding agents working in `xcode/`. Read [`README.md`](README.md) for building and the data pipeline, and [`ARCHITECTURE.md`](ARCHITECTURE.md) for how the code fits together.

## Commands

```bash
# Package tests: catalog, grouping, search, seed integrity
swift test --package-path DeadSheetsKit

# Builds (the iOS build includes the watch app)
xcodebuild build -project leadsheets.xcodeproj -scheme leadsheets -destination 'generic/platform=macOS' CODE_SIGNING_ALLOWED=NO
xcodebuild build -project leadsheets.xcodeproj -scheme leadsheets -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
xcodebuild build -project leadsheets.xcodeproj -scheme leadsheets -destination 'generic/platform=tvOS Simulator' CODE_SIGNING_ALLOWED=NO

# iPhone UI tests
xcodebuild test -project leadsheets.xcodeproj -scheme leadsheets -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM=

# Formatting
swift format lint --recursive --strict .
```

## Rules

- Keep every platform building: macOS, iOS + watchOS and tvOS. Shared views compile for tvOS, where `textSelection`, PDFKit and SwiftData-backed features don't exist.
- Put logic that doesn't need UIKit, AppKit or SwiftData in DeadSheetsKit, and test it with Swift Testing.
- Swift 6 with main-actor default isolation: mark delegate callbacks that arrive on background queues `nonisolated`. Use `@Observable`, `os.Logger` and async APIs, not `ObservableObject`, `print` or completion handlers.
- Don't edit `seeds.json` or the files in `Sheets/pdfs` by hand. `pnpm xcode` generates them from the Prisma database and iCloud Drive, using `Sheets/schema.json` to find each score, and the seed-integrity tests guard them.
- New user data goes in `Models/UserData.swift`, keyed by song slug, with no unique constraints and a default for every property.
- Give new list rows an accessibility identifier, and add a UI test for new navigation.

# Pre-Launch Checklist ✅

Before running your migrated app, verify these items:

## 📦 Required Files in Bundle

### Must Have:

- [ ] `seeds.json` is in project
- [ ] `seeds.json` is in "Copy Bundle Resources" (Build Phases → Copy Bundle Resources)
- [ ] All PDF files referenced in JSON are in bundle
- [ ] PDF files are also in "Copy Bundle Resources"

### How to Check:

1. Click project in Project Navigator
2. Select your target
3. Go to "Build Phases"
4. Expand "Copy Bundle Resources"
5. Verify JSON and PDFs are listed

## 🔨 Build Settings

- [ ] Deployment target is iOS 17.0 or later (for SwiftData)
- [ ] Swift Language Version is Swift 5.9 or later

### How to Check:

1. Project → Target → Build Settings
2. Search "deployment target"
3. Search "swift language version"

## 📝 Code Verification

### Files Exist:

- [ ] Song.swift (data models)
- [ ] DataImportService.swift (import logic)
- [ ] PDFKitView.swift (PDF display)
- [ ] SongDataManager.swift (helpers)

### Files Updated:

- [ ] LeadSheetsApp.swift has `.modelContainer()`
- [ ] ContentView.swift uses `@Query` and `allSongs`
- [ ] SearchScreen.swift accepts `songs: [Song]`
- [ ] PDFViewerScreen.swift accepts `song: Song`
- [ ] LyricsOverlay.swift accepts `song: Song`

## 🧪 First Build

1. [ ] Clean build folder (`Cmd+Shift+K`)
2. [ ] Build project (`Cmd+B`)
3. [ ] Fix any compiler errors
4. [ ] Run on simulator (`Cmd+R`)

## 🎬 First Launch

Watch for these console messages:

```
🔍 Looking for: seeds.json
✅ Found file at: [path]
📦 Data size: [X] bytes
📝 Decoded [N] songs
✅ Import complete!
Successfully imported [N] songs
```

If you see errors instead:

- Check `TROUBLESHOOTING.md`
- Verify JSON is in bundle
- Check JSON format is valid

## ✨ Test Functionality

### Basic Features:

- [ ] App launches without crashing
- [ ] Loading indicator shows briefly
- [ ] Song list appears
- [ ] Song count is correct
- [ ] Each song shows name and artist/album

### Search:

- [ ] Search bar is visible
- [ ] Typing filters results
- [ ] Search works for song names
- [ ] Search works for artist names
- [ ] Search works for album names
- [ ] Clearing search shows all songs

### Song Selection:

- [ ] Tapping song opens PDF viewer
- [ ] PDF displays correctly
- [ ] Back button works
- [ ] Transition animation is smooth

### Lyrics Overlay:

- [ ] Lyrics button visible in PDF viewer
- [ ] Tapping shows lyrics overlay
- [ ] Song name displays
- [ ] Artist displays (if available)
- [ ] Album displays (if available)
- [ ] Lyrics display (if available)
- [ ] Close button works
- [ ] Can drag overlay
- [ ] Can resize overlay

## 🔄 Second Launch

- [ ] App launches instantly (no import delay)
- [ ] All songs still present
- [ ] Search still works
- [ ] Everything functions normally

This confirms data is persisting correctly in SwiftData!

## 📊 Data Verification

Add this temporary button to ContentView to verify data:

```swift
// In ContentView body, add:
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        Button("Debug") {
            print("Total songs: \(allSongs.count)")
            print("Songs list:")
            allSongs.prefix(5).forEach { song in
                print("  - \(song.name) by \(song.artist?.name ?? "Unknown")")
            }
        }
    }
}
```

- [ ] Tap "Debug" button
- [ ] Check console output
- [ ] Verify song count matches your JSON
- [ ] Verify songs have correct names/artists

## 🚨 Common First-Run Issues

### No songs appear:

- JSON not in bundle
- Import failed (check console)
- Solution: See `TROUBLESHOOTING.md`

### App crashes:

- Old database conflicting
- Solution: Delete app, reinstall fresh

### PDFs don't show:

- PDF files not in bundle
- File names don't match
- Solution: Check "Copy Bundle Resources"

### Search doesn't work:

- Wrong variable passed to SearchScreen
- Should be `filteredSongs`, not `allSongs`

## ✅ Ready to Ship?

Once everything above passes:

- [ ] Test on multiple device sizes
- [ ] Test with many songs (performance)
- [ ] Test with no internet (offline)
- [ ] Test landscape orientation (if supported)
- [ ] Remove any debug print statements
- [ ] Remove debug buttons
- [ ] Archive and submit!

## 📚 Next Steps

After basic functionality works:

1. [ ] Read `README_SWIFTDATA.md` for overview
2. [ ] Review `AdvancedQueryExamples.swift` for ideas
3. [ ] Plan your next features
4. [ ] Start building!

## 🎉 Success Criteria

Your migration is successful when:

✅ App launches and imports songs on first run
✅ Songs display in list with correct info
✅ Search filters results correctly
✅ PDF viewer opens and displays PDFs
✅ Lyrics overlay shows and is interactive
✅ Second launch is instant (no re-import)
✅ App feels fast and responsive
✅ No crashes or errors

## 🆘 Need Help?

1. **Console Errors** → See `TROUBLESHOOTING.md`
2. **Understanding Code** → See `MIGRATION_GUIDE.md`
3. **Adding Features** → See `AdvancedQueryExamples.swift`
4. **General Overview** → See `README_SWIFTDATA.md`

---

**Good luck! You've got this! 🚀**

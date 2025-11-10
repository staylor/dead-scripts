# ⚡ Quick Start Guide

## 🚀 Ready to Run in 3 Steps

### Step 1: Build
```
Cmd + B
```
Fix any compiler errors (there shouldn't be any)

### Step 2: Run
```
Cmd + R
```
App will launch on simulator/device

### Step 3: Verify
- ✅ Loading indicator appears briefly
- ✅ Songs list appears
- ✅ Can search songs
- ✅ Can tap to view PDF
- ✅ Can view lyrics

**That's it! You're done! 🎉**

---

## 📖 What to Read Next

### If everything works:
1. **README_SWIFTDATA.md** - Understand what changed
2. **AdvancedQueryExamples.swift** - See what you can build

### If something's wrong:
1. **TROUBLESHOOTING.md** - Fix common issues
2. **CHECKLIST.md** - Verify setup

### To learn more:
1. **ARCHITECTURE.md** - Understand the design
2. **MIGRATION_GUIDE.md** - Technical details

---

## 🔥 Common First-Time Issues

### Issue: "No songs appear"
**Fix:** Check that `songs.json` is in "Copy Bundle Resources"
1. Project → Target → Build Phases
2. Expand "Copy Bundle Resources"
3. Ensure songs.json is listed

### Issue: "App crashes"
**Fix:** Clean build
```
Cmd + Shift + K  (Clean)
Cmd + B          (Build)
Cmd + R          (Run)
```

### Issue: "PDFs don't display"
**Fix:** Verify PDF files are in bundle resources (same as songs.json)

---

## 💡 Quick Tips

### Reset Import
If you updated songs.json:
1. Delete app from simulator
2. Run again (imports fresh)

### Debug Info
Add to ContentView temporarily:
```swift
.task {
    print("📊 Total songs: \(allSongs.count)")
}
```

### View Database
Add debug view:
```swift
List(allSongs) { song in
    VStack(alignment: .leading) {
        Text(song.name)
        Text(song.artist?.name ?? "No artist")
            .font(.caption)
    }
}
```

---

## ✨ Your New Capabilities

### Before:
- JSON loaded every time
- Simple song list
- Basic search

### Now:
- Instant app launches
- Rich data relationships
- Fast indexed search
- Artist/Album grouping
- Tag support
- Ready for advanced features

---

## 🎯 Test These

- [ ] Launch app (first time shows import)
- [ ] Search for a song name
- [ ] Search for an artist
- [ ] Tap a song (opens PDF)
- [ ] Tap lyrics button (shows overlay)
- [ ] Drag lyrics overlay
- [ ] Resize lyrics overlay
- [ ] Close lyrics overlay
- [ ] Go back to list
- [ ] Force quit app
- [ ] Relaunch (instant, no import)

---

## 📚 Documentation Index

| File | Purpose | Read When |
|------|---------|-----------|
| **SUMMARY.md** | Overview | First |
| **README_SWIFTDATA.md** | User guide | After first run |
| **CHECKLIST.md** | Pre-launch | Before running |
| **TROUBLESHOOTING.md** | Problem solving | When issues occur |
| **MIGRATION_GUIDE.md** | Technical details | Understanding changes |
| **ARCHITECTURE.md** | System design | Planning features |
| **AdvancedQueryExamples.swift** | Code examples | Building features |

---

## 🆘 Still Stuck?

1. Check the console for error messages
2. Open relevant doc from table above
3. Try clean build (Cmd+Shift+K)
4. Delete app and reinstall fresh

---

## 🎉 Success!

When you see your songs list and can search/view PDFs, you're done!

**Your app now uses SwiftData and is ready to scale! 🚀**

Next: Plan what features to build next using `AdvancedQueryExamples.swift`

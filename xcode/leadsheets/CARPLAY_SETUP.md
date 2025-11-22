# CarPlay Setup Instructions

To enable CarPlay support in your Lead Sheets app, you need to configure your Xcode project with the following steps:

## 1. Add CarPlay Entitlement

1. Select your project in Xcode
2. Select your app target
3. Go to the "Signing & Capabilities" tab
4. Click the "+ Capability" button
5. Search for and add "CarPlay"
6. In the CarPlay section, check the box for "Audio" (this allows playback apps)

## 2. Configure Info.plist

Add the following keys to your `Info.plist`:

```xml
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <true/>
    <key>UISceneConfigurations</key>
    <dict>
        <key>CPTemplateApplicationSceneSessionRoleApplication</key>
        <array>
            <dict>
                <key>UISceneConfigurationName</key>
                <string>CarPlay Configuration</string>
                <key>UISceneDelegateClassName</key>
                <string>$(PRODUCT_MODULE_NAME).CarPlaySceneDelegate</string>
            </dict>
        </array>
        <key>UIWindowSceneSessionRoleApplication</key>
        <array>
            <dict>
                <key>UISceneConfigurationName</key>
                <string>Default Configuration</string>
            </dict>
        </array>
    </dict>
</dict>
```

## 3. Testing CarPlay

### Using Xcode Simulator:
1. Run your app in the iOS Simulator
2. In the simulator menu, go to: **I/O → External Displays → CarPlay**
3. A CarPlay window will appear
4. Your app should appear in the CarPlay home screen

### Using a Physical Device:
You'll need either:
- A car with CarPlay support
- An aftermarket CarPlay head unit
- A CarPlay development dongle from Apple

## 4. How It Works

The CarPlay implementation:

1. **CarPlaySceneDelegate** - Manages the CarPlay interface and displays your song list
2. **Song List Template** - Shows all songs grouped alphabetically with sections
3. **Apple Music Integration** - When a song is tapped, it opens in Apple Music using the stored Apple Music ID

## Features

- ✅ Alphabetically organized song list with sections
- ✅ Search support (built-in to CarPlay list templates)
- ✅ Tap to play in Apple Music
- ✅ Shows artist name as detail text
- ✅ Safe, template-based UI approved for driving

## Requirements

- iOS 14.0 or later
- CarPlay entitlement from Apple (for App Store distribution)
- Songs must have Apple Music IDs to be playable

## Notes

- The CarPlay interface is read-only and optimized for safety
- PDFs and lyrics cannot be displayed in CarPlay due to safety restrictions
- The app focuses on quick access to play songs in Apple Music
- CarPlay apps must use Apple's templated UI system

# StreamWave Radio - Native App Setup

This guide explains how to build and run StreamWave Radio as a native iOS and Android app using Capacitor.

## Prerequisites

### For iOS Development
- macOS computer
- Xcode 15+ installed
- CocoaPods installed: `sudo gem install cocoapods`
- Apple Developer account (for device testing and App Store distribution)

### For Android Development
- Android Studio installed
- Java Development Kit (JDK) 17+
- Android SDK installed via Android Studio

### General Requirements
- Node.js 18+ and npm installed

## Project Structure

```
StreamWave-Radio/
├── www/              # Built web assets (generated)
├── ios/              # iOS native project (generated)
├── android/          # Android native project (generated)
├── *.html            # Source web files
├── *.js              # Source JavaScript files
├── css/              # Stylesheets
├── icons/            # App icons
└── capacitor.config.json  # Capacitor configuration
```

## Initial Setup

1. **Install Dependencies**
   ```bash
   npm install
   ```

2. **Build Web Assets**
   ```bash
   npm run build
   ```
   This copies your web files to the `www/` directory.

3. **Sync Native Projects**
   ```bash
   npm run sync
   ```
   This updates both iOS and Android projects with the latest web assets and plugins.

## Development Workflow

### Building for iOS

1. **Sync and Open Xcode**
   ```bash
   npm run sync:ios
   npm run open:ios
   ```

2. **In Xcode:**
   - Select your development team in Signing & Capabilities
   - Choose a simulator or connected iOS device
   - Click the Play button to build and run

3. **After Making Web Changes:**
   ```bash
   npm run sync:ios
   ```
   Then rebuild in Xcode (Cmd+B)

### Building for Android

1. **Sync and Open Android Studio**
   ```bash
   npm run sync:android
   npm run open:android
   ```

2. **In Android Studio:**
   - Wait for Gradle sync to complete
   - Select an emulator or connected Android device
   - Click Run (green play button)

3. **After Making Web Changes:**
   ```bash
   npm run sync:android
   ```
   Then rebuild in Android Studio

## Available NPM Scripts

- `npm run build` - Copy web files to www/ directory
- `npm run copy` - Same as build
- `npm run sync` - Sync both iOS and Android
- `npm run sync:ios` - Sync only iOS
- `npm run sync:android` - Sync only Android
- `npm run open:ios` - Open iOS project in Xcode
- `npm run open:android` - Open Android project in Android Studio

## Installed Capacitor Plugins

### Core Plugins
- **@capacitor/app** - App lifecycle and URL handling
- **@capacitor/splash-screen** - Splash screen management
- **@capacitor/status-bar** - Status bar styling
- **@capacitor/browser** - In-app browser

### Community Plugins
- **@capacitor-community/media** - Media session and lock screen controls
- **@capacitor-community/background-geolocation** - Background task support

## Key Configuration Files

### capacitor.config.json
Main Capacitor configuration. Key settings:
- `appId`: com.streamwave.radio
- `appName`: StreamWave Radio
- `webDir`: www (where built web assets are located)
- `server.androidScheme`: https (for Android security)

### iOS Configuration
- **Info.plist location**: `ios/App/App/Info.plist`
- Add required permissions here (microphone, media library, etc.)

### Android Configuration
- **AndroidManifest.xml**: `android/app/src/main/AndroidManifest.xml`
- **build.gradle**: `android/app/build.gradle`
- Add required permissions in AndroidManifest.xml

## Adding Native Features

### Background Audio Playback

To enable background audio (crucial for radio streaming):

#### iOS
Add to `ios/App/App/Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

#### Android
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### Media Controls

Use the `@capacitor-community/media` plugin for lock screen controls:

```javascript
import { MediaSession } from '@capacitor-community/media';

await MediaSession.setMetadata({
    title: 'Song Title',
    artist: 'Artist Name',
    album: 'Album Name',
    artwork: [
        { src: 'artwork-url', sizes: '512x512', type: 'image/png' }
    ]
});
```

## Testing

### iOS Simulator
- Quick testing without a device
- Limited audio capabilities
- Test on real device for audio features

### Android Emulator
- Full audio support
- Slower than iOS simulator
- Ensure "Audio Output" is enabled in AVD settings

### Real Devices
- Required for final testing
- Test background audio playback
- Test lock screen controls
- Test app lifecycle (background/foreground)

## Building for Production

### iOS App Store

1. **Archive the app in Xcode:**
   - Product → Archive
   - Validate and upload to App Store Connect

2. **Requirements:**
   - App icons (all sizes in `ios/App/App/Assets.xcassets/AppIcon.appiconset/`)
   - Launch screen configured
   - Privacy descriptions in Info.plist
   - App Store screenshots and metadata

### Android Play Store

1. **Generate signed APK/Bundle:**
   - Build → Generate Signed Bundle/APK in Android Studio
   - Create or use existing keystore

2. **Requirements:**
   - App icons in correct densities
   - Update version in `android/app/build.gradle`
   - Privacy policy URL
   - Play Store screenshots and metadata

## Troubleshooting

### iOS Build Errors
- Clean build folder: Product → Clean Build Folder in Xcode
- Update CocoaPods: `cd ios/App && pod install --repo-update`
- Check signing certificates and provisioning profiles

### Android Build Errors
- Invalidate caches: File → Invalidate Caches / Restart in Android Studio
- Clean project: Build → Clean Project
- Check Gradle version compatibility

### Web Assets Not Updating
- Run `npm run build` to copy latest files
- Run `npx cap sync` to update native projects
- For iOS: Clean and rebuild in Xcode
- For Android: Rebuild in Android Studio

### Plugin Errors
- Ensure all plugins are installed: `npm install`
- Sync plugins: `npx cap sync`
- Check plugin compatibility with your Capacitor version

## Live Reload During Development

For faster development, you can use Capacitor's live reload:

1. **Start a local web server:**
   ```bash
   npx http-server www -p 8080
   ```

2. **Update capacitor.config.json temporarily:**
   ```json
   {
     "server": {
       "url": "http://YOUR_LOCAL_IP:8080",
       "cleartext": true
     }
   }
   ```

3. **Sync and run:**
   ```bash
   npx cap sync
   ```

4. **Remember to remove the server config before production builds!**

## Additional Resources

- [Capacitor Documentation](https://capacitorjs.com/docs)
- [iOS Developer Documentation](https://developer.apple.com/documentation/)
- [Android Developer Documentation](https://developer.android.com/docs)
- [Capacitor Plugins](https://capacitorjs.com/docs/plugins)

## Support

For issues specific to the native app setup:
1. Check the Capacitor docs
2. Review plugin documentation
3. Check Xcode/Android Studio console for errors
4. Search Capacitor GitHub issues

## Next Steps

1. Customize app icons in `ios/` and `android/` directories
2. Update splash screens
3. Add required permissions for your features
4. Test background audio playback
5. Implement media session controls
6. Test on real devices
7. Prepare for app store submission

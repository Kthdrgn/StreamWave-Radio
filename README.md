# StreamWave Radio

A radio streaming application with live metadata and album art. Available as a Progressive Web App (PWA) and native iOS/Android apps.

## Features

- Stream radio stations with live metadata
- Display album artwork
- Google Chromecast support
- Curated playlists and station search
- Background audio playback (native apps)
- Lock screen media controls (native apps)

## Getting Started

### Web App (PWA)
Simply open `index.html` in a web browser or deploy to any web hosting service.

### Native Apps (iOS/Android)
See [NATIVE_APP_SETUP.md](NATIVE_APP_SETUP.md) for detailed instructions on building and running the native mobile apps.

Quick start:
```bash
npm install
npm run build
npm run sync
npm run open:ios    # For iOS
npm run open:android # For Android
```

## Technology Stack

- Vanilla JavaScript (no framework)
- Capacitor (for native app conversion)
- Supabase (backend)
- icecast-metadata-player (radio streaming)
- Google Cast SDK (Chromecast support)

## Documentation

- [Native App Setup Guide](NATIVE_APP_SETUP.md) - Build and deploy iOS/Android apps
- [Curated Playlists Implementation](CURATED_PLAYLISTS_IMPLEMENTATION.md) - Playlist feature details
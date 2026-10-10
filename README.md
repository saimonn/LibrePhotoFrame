# LibrePhotoFrame

<p align="center">
  <img src="assets/icon.png" alt="LibrePhotoFrame Icon" width="128" height="128">
</p>

**Turn your old Android tablet into a beautiful digital photo frame.**

LibrePhotoFrame is a free, open-source slideshow app forked from [OpenPhotoFrame](https://github.com/micw/OpenPhotoFrame) by Michael Wyraz. It carries the spirit forward without CLA constraints, focusing on a modern, maintained Android photo frame experience.

## ✨ Features

- **Beautiful Slideshow** – Smooth crossfade transitions with portrait/landscape pairing for optimal viewing
- **Nextcloud/WebDAV Sync** – Sync from public Nextcloud shares or authenticated WebDAV
- **Local Folder Sync** – Watch local directories, periodic polling with file-growth detection, and orphan cleanup
- **Device Photos (MediaStore)** – Show your device albums with automatic refresh
- **Photo Metadata** – SQLite-backed caching for EXIF, GPS, dimensions, and geocoding results
- **Geocoding** – Reverse-geocode with in-memory deduplication and persistent caching (Nominatim)
- **Display Control** – Schedule day/night modes; supports native screen control on rooted/Device Owner setups
- **Keep-Alive** – Foreground service to prevent the frame from being killed
- **Clock & Calendar Overlays** – Customizable overlays with locale-aware formatting
- **Split-Screen Pairing** – Intelligent portrait/landscape pairing
- **Automatic Updates** – Opt-in updates from GitHub releases (silent install with Device Owner)
- **Privacy First** – No ads, no subscriptions, no tracking

## 📦 Installation

### Android
APK builds are available from GitHub Actions artifacts and releases. F-Droid packaging may follow.

## 🛠️ Development

### Requirements
- Flutter SDK (3.x)
- Dart SDK

### Build & Run
```bash
git clone https://github.com/saimonn/LibrePhotoFrame.git
cd LibrePhotoFrame
flutter pub get
flutter run -d linux  # or connected Android device
```

## Credits

- Original work: [Michael Wyraz](https://github.com/micw) - [OpenPhotoFrame](https://github.com/micw/OpenPhotoFrame)
- Fork and maintenance: [saimonn](https://github.com/saimonn)
- All contributors

## License

GPLv3

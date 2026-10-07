# LibrePhotoFrame

<p align="center">
  <img src="assets/icon.png" alt="LibrePhotoFrame Icon" width="128" height="128">
</p>

**Turn your old Android tablet into a beautiful digital photo frame.**

LibrePhotoFrame is a free, open-source slideshow app that syncs photos from your private cloud (Nextcloud) or local storage. No ads, no subscriptions, no nag screens – just your photos.

> **This project is a fork.** It was originally developed as [OpenPhotoFrame](https://github.com/micw/OpenPhotoFrame) by Michael Wyraz, and forked and renamed to LibrePhotoFrame to carry it forward. All credit for the original work goes to him.

## ✨ Features

- **🖼️ Beautiful Slideshow** – Smooth crossfade transitions between your photos
- **☁️ Nextcloud Sync** – Sync photos from a Nextcloud public share link or a WebDAV login
- **📁 Local First** – Works offline from a watched folder: Syncthing, a Nextcloud desktop client, rsync or a network mount can fill it, and the frame picks up added and removed photos on its own (see below)
- **📱 Device Photos** – Show the albums of the device itself, refreshed while the frame runs
- **🖼️🖼️ Split Screen** – Show two photos at once when they match the shape of the screen
- **⚙️ Simple Settings** – Slide duration, transition speed, photo order, clock, screen orientation, language
- **🌙 Always On** – Designed to run 24/7 as a dedicated photo frame
- **🔒 Privacy First** – Your photos stay on your server, no third-party cloud required

## 🚀 Why LibrePhotoFrame?

Existing apps like *Fotoo* or *PhotoCloud Frame Slideshow* are either:
- Riddled with **ads and nag screens**
- Require **paid subscriptions** for basic features
- Force you to use **public cloud services** (Google Photos, etc.)

LibrePhotoFrame is different:
- ✅ **100% Free & Open Source** (GPLv3)
- ✅ **No ads, no in-app purchases, no tracking**
- ✅ **Works with your self-hosted Nextcloud**
- ✅ **Simple & focused** – does one thing well (KISS principle)

## 📦 Installation

### Android
*Coming soon to F-Droid*

For now, build from source (see Development section).

### Linux (for Development/Testing)
```bash
flutter run -d linux
```

## 📁 Filling the frame from a synced folder

The frame needs no sync client of its own. Point it at a folder that something else keeps up to date — [Syncthing](https://syncthing.net), a Nextcloud or Seafile desktop client, `rsync` over SSH, a Samba/NFS mount, a USB stick — and the slideshow follows that folder:

1. **Settings → Photo Source → Local Folder**, then pick the folder. Use *App Folder* instead to keep the photos inside the app storage (they are then deleted when the app is uninstalled).
2. Turn on **Watch Folder**.

Two independent mechanisms keep the list in sync, because neither is enough alone:

- **File system events** (`Directory.watch`) react within milliseconds, but Android external storage and SD cards are mounted through FUSE, and files written by another app frequently produce no event at all.
- **A periodic rescan** (60 seconds by default) is the safety net and picks up everything an event missed. The interval is set in **Settings → Photo Source → Poll interval**.

A photo a sync client drops into the folder therefore appears within about a minute by default even when no event is delivered, and immediately when one is. Deleted files drop out of the list on the next scan, and subfolders are scanned too. A new photo is published only once it stopped growing, so a file that is still being copied is never shown half-written.

Turning **Watch Folder** off leaves only the periodic rescan. In folder mode the app reads `.jpg`, `.jpeg`, `.png` and `.webp` (case insensitive); other formats such as HEIC, AVIF or RAW are ignored.

## 🔄 Automatic Updates

LibrePhotoFrame can update itself from GitHub releases. It is **opt-in** and **off by default** — enable it at the bottom of **Settings → Automatic updates**. This is only for installs from GitHub; if you installed via F-Droid, leave it off and update through F-Droid instead.

When enabled, the app checks the latest GitHub release roughly every 8 hours:

- **Default:** when a newer version is found you get a prompt to *Skip* or *Download & install*. Android then shows its install confirmation (you may need to allow "Install unknown apps" once).
- **Silent:** if the app is the device's **Device Owner**, updates download and install silently in the background with no prompt — ideal for a wall-mounted frame you never touch.

### Silent updates via Device Owner

Device Owner is Android's device-management mode. It is what lets the app install updates without any confirmation dialog. It can only be set on a device with **no accounts** (e.g. right after a factory reset), via ADB:

```bash
adb shell dpm set-device-owner io.github.saimonn.librephotoframe/.ScreenAdminReceiver
```

Then enable **Settings → Automatic updates → Install without confirmation**. To remove it again later:

```bash
adb shell dpm remove-active-admin io.github.saimonn.librephotoframe/.ScreenAdminReceiver
```

> Updates only install over an existing app when signed with the same key. The project's reproducible builds ensure the GitHub APKs match the F-Droid signing key, so switching between them keeps your data.

## 🛠️ Development

### Requirements
- Flutter SDK (3.x)
- Dart SDK

### Build & Run
```bash
# Clone the repository
git clone https://github.com/saimonn/LibrePhotoFrame.git
cd LibrePhotoFrame

# Get dependencies
flutter pub get

# Run on Linux (fast iteration)
flutter run -d linux

# Run on connected Android device
flutter run -d <device-id>
```

### Updating the App Icon
To update the app icon, replace `assets/icon.png` with your new icon (recommended: 1024x1024 PNG), then run:
```bash
dart run flutter_launcher_icons
cp assets/icon.png fastlane/metadata/android/en-US/images/icon.png
```
This generates icons for all platforms (Android, iOS, Web, Windows, macOS, Linux) and updates the F-Droid metadata.

### Architecture
The app follows a **Local First** architecture with clean separation of concerns:

- **Player (UI)** – Displays photos from a local directory with smooth transitions
- **Syncer (Service)** – Downloads photos from cloud sources in the background
- **Repository Pattern** – Abstracts storage access
- **Strategy Pattern** – Swappable playlist algorithms (random, weighted freshness)

## ⚙️ Configuration

Tap the center of the screen during slideshow to open settings:

| Setting | Description |
|---------|-------------|
| Slide Duration | How long each photo is shown (1-15 min) |
| Transition Duration | Crossfade animation speed (0.5-5 sec) |
| Sync Source | None or Nextcloud public share link |
| Sync Interval | Auto-sync frequency (disabled, or 5-60 min) |
| Delete Orphaned Files | Remove local photos deleted from server |

### 💡 Tip: Enter URL via ADB

If typing the Nextcloud URL on a tablet is cumbersome, you can paste it via ADB:

```bash
# Focus the URL input field on the tablet, then run:
adb shell input text 'https://cloud.example.com/s/YOUR_SHARE_TOKEN'
```

### 💡 Tip: Disable Lock Screen via ADB

Some Android devices (especially Huawei with EMUI) don't allow disabling the lock screen in the settings UI. You can disable it via ADB:

```bash
adb shell locksettings set-disabled true
```

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting a pull request.

## 📄 License

This project is licensed under the **GNU General Public License v3.0**.

See the [LICENSE](LICENSE) file for details.

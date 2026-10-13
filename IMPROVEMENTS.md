# Improvement Proposals

## 1. Ergonomie / UX (for old tablets and kiosk mode)

- **Collapsible settings sections with state persistence**: Group settings (Slideshow, Clock, Photo Info, Calendar, Sync, Display, Updates, etc.) into expandable/collapsible sections. Persist which sections are expanded in SharedPreferences. This reduces scrolling on small screens.
- **Quick search/filter in settings**: Add a search bar at the top of Settings to filter tiles by title/subtitle keywords, making navigation faster on dense configs.
- **Presets (Performance/Battery/Quality)**: Add presets like "Low Power" (longer intervals, no blur, reduced prefetch, conservative quality), "Balanced" (default), "Quality" (shorter intervals, prefetch, blur). Selecting a preset should set multiple related fields.
- **Touch targets & spacing**: Enforce min 48dp touch targets (color swatches already improved; extend to dropdowns/tiles) and increase vertical spacing for easier use on resistive/older touch screens.
- **Reduce motion setting**: Add "Reduce motion" toggle to disable or simplify transitions on low-end devices.
- **Kiosk-friendly controls** (optional): PIN protection for Settings, auto-timeout on Settings screen to prevent accidental changes.
- **Better empty/error states**: Clear guidance when no photos found, with retry and basic diagnostics.

## 2. Performances / Resource Usage (old tablets)

- **Adaptive image resolution**: Wrap image providers with ResizeImage to decode at target display/cell size (not full resolution). Add quality tiers (low/med/high).
- **Memory-aware image cache**: Dynamically set PaintingBinding.instance.imageCache maxSizeBytes/maxSize based on detected RAM (smaller limits for < 2GB).
- **Adaptive prefetch**: Only prefetch next image(s) when device has sufficient RAM/CPU headroom; cap to 1 image on low-end; can be disabled by preset.
- **Throttle blur on low-end**: Auto-reduce blur sigma or disable BackdropFilter on low-GPU devices (respect preset).
- **Pause on screen off/battery low**: Detect screen state/battery level and pause timers/loading when appropriate (respect keep-alive).
- **Optimize EXIF/dimensions cache I/O**: Add in-memory LRU cache for places/dimensions before hitting SQLite to reduce I/O.
- **Reduce logging overhead**: Make log level configurable; keep minute-aligned clock timer as is.

## 3. Test Coverage

- **Color utils unit tests**: Test hex parsing (#RGB, #RRGGBB, #AARRGGBB), named colors, invalid inputs.
- **Geocoding service tests**: Single-flight deduplication, caching/miss caching behavior, pruning, network failures, malformed responses.
- **Photo metadata DB tests**: Schema, migrations, corruption, pruning, concurrent access.
- **Prefetch logic tests**: Verify prefetch called appropriately and handles errors.
- **Settings interaction tests**: Color swatch selection, preset application, collapsible sections.
- **Golden tests**: Expand to Calendar/Clock/PhotoInfo with various states (colors, enhanced contrast, script font, many events).
- **Platform/permissions tests**: Mock calendar/storage/keep-alive, test denial flows.
- **Config migration tests**: Backward compatibility with new fields (photoFit, colors, etc.).

## 4. Code Quality / Maintenance

- **Extract color parsing utilities** (DRY between Settings and Slideshow).
- **Add RepaintBoundaries around overlay stack** (cheap repaint isolation).
- **Fix async context warnings** (use_build_context_synchronously).
- **Unify overlay style config** (shared model for clock/photo info/calendar).
- **Export/import config** (backup/migration).

## 5. Documentation

- **README**: Add quick mention of Syncthing/local folder sync. Suggest using Syncthing (or Syncthing-Fork) to sync photos to the device's local folder ("Local folder" sync mode) - convenient for keeping a curated set on the frame without cloud services.

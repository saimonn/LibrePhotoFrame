import '../models/photo_entry.dart';

abstract class PlaylistStrategy {
  /// Selects the next photo to display from the list of available photos.
  /// [availablePhotos] is the list of all photos on the device.
  PhotoEntry? nextPhoto(List<PhotoEntry> availablePhotos);

  /// Records what the frame is showing right now.
  ///
  /// The slideshow calls this with the photo and, in split mode, the photo it
  /// shares the frame with, so a strategy that depends on what was shown
  /// recently sees both at the same rank. Strategies that do not care ignore it.
  void recordShown(List<PhotoEntry> photos) {}

  /// Photos that would be shown next, up to [count], without changing the
  /// state of the strategy.
  ///
  /// Returns an empty list when the order cannot be previewed. Used to warm the
  /// image cache ahead of the next slide.
  List<PhotoEntry> peekNextPhotos(List<PhotoEntry> availablePhotos, int count) =>
      const [];

  /// Returns a unique identifier for this strategy (e.g. "random")
  String get id;

  /// Returns a human readable name (e.g. "Random order")
  String get name;
}

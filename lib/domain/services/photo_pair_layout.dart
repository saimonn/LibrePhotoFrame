import '../models/photo_entry.dart';

/// Which photos share a screen, and how they are arranged.
///
/// On a landscape frame two portrait photos sit next to each other; on a
/// portrait frame two landscape photos are stacked. That pairing fills the
/// frame instead of letterboxing a single photo, which is why it is keyed off
/// the frame orientation rather than the photo orientation.
enum PhotoPairing {
  /// Single photo fills the frame.
  single,

  /// Two portrait photos side by side (landscape frame).
  portraitSideBySide,

  /// Two landscape photos stacked vertically (portrait frame).
  landscapeStacked,
}

/// Decides the pairing for a frame and picks the photos that go on it.
///
/// Pure logic on purpose: no Flutter, no IO, so it can be unit tested without a
/// renderer. Resolving the pixel dimensions a photo needs to qualify lives in
/// `PhotoDimensionsService`.
class PhotoPairLayout {
  const PhotoPairLayout._();

  /// Returns the pairing to use for a frame of [width] x [height].
  static PhotoPairing forScreen(double width, double height) {
    if (width > height) return PhotoPairing.portraitSideBySide;
    return PhotoPairing.landscapeStacked;
  }

  /// Whether this pairing shows two photos.
  static bool isPaired(PhotoPairing pairing) => pairing != PhotoPairing.single;

  /// The shape a photo must have to take part in [pairing], or null when
  /// any photo qualifies.
  ///
  /// A landscape frame pairs portrait photos, a portrait frame pairs landscape
  /// photos. Square photos never pair, because they would leave a gap.
  static PhotoShape? requiredShape(PhotoPairing pairing) {
    switch (pairing) {
      case PhotoPairing.portraitSideBySide:
        return PhotoShape.portrait;
      case PhotoPairing.landscapeStacked:
        return PhotoShape.landscape;
      case PhotoPairing.single:
        return null;
    }
  }

  /// Whether [photo] can take part in [pairing].
  static bool accepts(PhotoPairing pairing, PhotoEntry photo) {
    final required = requiredShape(pairing);
    if (required == null) return true;
    return photo.shape == required;
  }

  /// Picks the partner for [primary] from [candidates].
  ///
  /// Returns null when [primary] or no candidate matches the required shape, in
  /// which case the frame simply shows [primary] alone. [excludePaths] prevents
  /// pairing a photo with itself or with the photo already on screen.
  static PhotoEntry? partnerFor({
    required PhotoEntry primary,
    required List<PhotoEntry> candidates,
    required PhotoPairing pairing,
    Set<String> excludePaths = const {},
  }) {
    if (!isPaired(pairing)) return null;
    if (!accepts(pairing, primary)) return null;

    final required = requiredShape(pairing);
    final excluded = {...excludePaths, primary.file.path};

    // Prefer a candidate that matches the required shape exactly.
    for (final candidate in candidates) {
      if (excluded.contains(candidate.file.path)) continue;
      if (candidate.shape == required) return candidate;
    }
    return null;
  }
}

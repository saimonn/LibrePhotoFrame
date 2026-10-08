import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../domain/models/photo_entry.dart';
import '../../domain/services/photo_pair_layout.dart';

class PhotoSlide extends StatelessWidget {
  final PhotoEntry photo;
  final Size screenSize;
  final bool blurBorders;

  /// Second photo to show next to [photo]. When set, the two are laid out
  /// according to [pairing]: portrait photos side by side on a landscape
  /// frame, landscape photos stacked on a portrait frame.
  final PhotoEntry? partner;
  final PhotoPairing pairing;

  const PhotoSlide({
    super.key,
    required this.photo,
    required this.screenSize,
    required this.blurBorders,
    this.partner,
    this.pairing = PhotoPairing.single,
  });

  /// Gap between the two photos of a paired layout, in logical pixels.
  static const double pairGap = 2.0;

  /// Size of the box a single photo occupies on a frame of [screenSize].
  ///
  /// A paired layout gives each photo half the frame, so decoding at the full
  /// screen size would waste memory on a low-RAM frame. Preloading must use
  /// this same size, otherwise the [ResizeImage] cache key misses and the photo
  /// gets decoded a second time during the transition.
  static Size cellSize(Size screenSize, PhotoPairing pairing) {
    switch (pairing) {
      case PhotoPairing.portraitSideBySide:
        return Size(
          (screenSize.width - pairGap) / 2,
          screenSize.height,
        );
      case PhotoPairing.landscapeStacked:
        return Size(
          screenSize.width,
          (screenSize.height - pairGap) / 2,
        );
      case PhotoPairing.single:
        return screenSize;
    }
  }

  /// Boxes the photos of [pairing] occupy on a frame of [screenSize], in the
  /// order [build] paints them: the main photo first, the partner second.
  ///
  /// The photo info overlay aligns itself inside these boxes, so each photo of
  /// a split screen gets its own corner instead of one overlay for the frame.
  static List<Rect> cellRects(Size screenSize, PhotoPairing pairing) {
    final cell = cellSize(screenSize, pairing);
    switch (pairing) {
      case PhotoPairing.portraitSideBySide:
        return [
          Rect.fromLTWH(0, 0, cell.width, screenSize.height),
          Rect.fromLTWH(cell.width + pairGap, 0, cell.width, screenSize.height),
        ];
      case PhotoPairing.landscapeStacked:
        return [
          Rect.fromLTWH(0, 0, screenSize.width, cell.height),
          Rect.fromLTWH(0, cell.height + pairGap, screenSize.width, cell.height),
        ];
      case PhotoPairing.single:
        return [Rect.fromLTWH(0, 0, screenSize.width, screenSize.height)];
    }
  }

  /// Creates a ResizeImage provider optimized for [boxSize].
  /// This significantly speeds up decoding on slower devices.
  static ImageProvider createOptimizedProvider(File file, Size boxSize) {
    // Use the larger dimension to ensure the image covers the box
    // Adding some buffer for quality (1.2x)
    final targetSize = (boxSize.longestSide * 1.2).toInt();
    return ResizeImage(
      FileImage(file),
      width: targetSize,
      height: targetSize,
      policy: ResizeImagePolicy.fit,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use ResizeImage for faster decoding - loads image at cell resolution
    final cell = cellSize(screenSize, partner == null ? PhotoPairing.single : pairing);
    final content = _buildCell(createOptimizedProvider(photo.file, cell));

    final second = partner;
    if (second == null || !PhotoPairLayout.isPaired(pairing)) return content;

    // Paired layout. Each photo keeps BoxFit.contain so it is never cropped,
    // and a hairline gap keeps the two from bleeding into each other when the
    // blurred background shows through.
    const gap = pairGap;
    final secondCell = _buildCell(createOptimizedProvider(second.file, cell));

    if (pairing == PhotoPairing.portraitSideBySide) {
      return Row(
        children: [
          Expanded(child: content),
          const SizedBox(width: gap),
          Expanded(child: secondCell),
        ],
      );
    }

    return Column(
      children: [
        Expanded(child: content),
        const SizedBox(height: gap),
        Expanded(child: secondCell),
      ],
    );
  }

  /// One photo: optional blurred backdrop plus the photo itself.
  ///
  /// Both halves of a paired layout go through this, so `blurBorders` looks the
  /// same on each side instead of one half being bare black.
  Widget _buildCell(ImageProvider imageProvider) {
    // The explicit ClipRect is what keeps the blurred backdrop inside its own
    // half. A Stack only clips when a positioned child overflows it, and this
    // one never does, so without the clip the BackdropFilter would blur
    // everything painted before it, including the photo in the other half.
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (blurBorders) ...[
            Image(
              image: imageProvider,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          ] else
            Container(
              color: Colors.black,
            ),
          // 2. Main Image
          // Positioned.fill gives the Image tight (full-cell) constraints so
          // BoxFit.contain scales the photo up as well as down. A plain Center
          // would leave the Image at its intrinsic size, so smaller-than-screen
          // photos would not be scaled up. The image stays centered via the
          // default alignment.
          Positioned.fill(
            child: Image(
              image: imageProvider,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../domain/models/photo_entry.dart';
import '../../domain/services/photo_pair_layout.dart';
import 'photo_slide.dart';

/// Places one photo info overlay per photo on the frame.
///
/// A single photo takes the whole frame, a paired layout gets one overlay per
/// half, aligned in the box of the photo it belongs to.
///
/// The boxes are computed from the frame in **logical** pixels, the coordinate
/// space `Positioned` works in. The slideshow keeps its screen size in physical
/// pixels to size the image decodes; using that size here scaled the second box
/// off the frame on high-density screens (issue 12).
class PhotoInfoLayers extends StatelessWidget {
  const PhotoInfoLayers({
    super.key,
    required this.photo,
    required this.overlayBuilder,
    this.partner,
  });

  final PhotoEntry photo;

  /// Second photo of the frame, when there is one.
  final PhotoEntry? partner;

  /// Builds the overlay of a given photo, so the caller keeps ownership of the
  /// display settings (position, size, font).
  final Widget Function(PhotoEntry photo) overlayBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final frame = Size(constraints.maxWidth, constraints.maxHeight);
        final partner = this.partner;
        // Derive the pairing from the same frame as the boxes, so the two can
        // never disagree on which half a photo takes.
        final pairing = PhotoPairLayout.forScreen(frame.width, frame.height);
        if (partner == null || !PhotoPairLayout.isPaired(pairing)) {
          return overlayBuilder(photo);
        }

        final boxes = PhotoSlide.cellRects(frame, pairing);
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fromRect(rect: boxes[0], child: overlayBuilder(photo)),
            Positioned.fromRect(rect: boxes[1], child: overlayBuilder(partner)),
          ],
        );
      },
    );
  }
}

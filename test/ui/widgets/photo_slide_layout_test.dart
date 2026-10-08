import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:libre_photo_frame/domain/services/photo_pair_layout.dart';
import 'package:libre_photo_frame/ui/widgets/photo_slide.dart';

/// Split screens paint one info overlay per photo (issue 09), each aligned in
/// the box of its own picture, so those boxes have to tile the frame exactly
/// the way PhotoSlide lays the photos out.
void main() {
  const gap = PhotoSlide.pairGap;

  test('side by side boxes are the two halves of a landscape frame', () {
    const screen = Size(2560, 1600);
    const pairing = PhotoPairing.portraitSideBySide;
    final cell = PhotoSlide.cellSize(screen, pairing);
    final boxes = PhotoSlide.cellRects(screen, pairing);

    expect(boxes, hasLength(2));
    expect(boxes[0], Rect.fromLTWH(0, 0, cell.width, screen.height));
    expect(
      boxes[1],
      Rect.fromLTWH(cell.width + gap, 0, cell.width, screen.height),
    );
    expect(boxes.first.topLeft, Offset.zero);
    expect(boxes.last.bottomRight, Offset(screen.width, screen.height));
  });

  test('stacked boxes are the two halves of a portrait frame', () {
    const screen = Size(1600, 2560);
    const pairing = PhotoPairing.landscapeStacked;
    final cell = PhotoSlide.cellSize(screen, pairing);
    final boxes = PhotoSlide.cellRects(screen, pairing);

    expect(boxes, hasLength(2));
    expect(boxes[0], Rect.fromLTWH(0, 0, screen.width, cell.height));
    expect(
      boxes[1],
      Rect.fromLTWH(0, cell.height + gap, screen.width, cell.height),
    );
    expect(boxes.first.topLeft, Offset.zero);
    expect(boxes.last.bottomRight, Offset(screen.width, screen.height));
  });

  test('a single photo takes the whole frame', () {
    const screen = Size(2560, 1600);
    final boxes = PhotoSlide.cellRects(screen, PhotoPairing.single);

    expect(boxes, [Rect.fromLTWH(0, 0, screen.width, screen.height)]);
  });
}

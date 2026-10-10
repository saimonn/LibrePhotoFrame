import 'package:flutter/material.dart';

/// Where an overlay (clock, calendar, photo info) sits on the frame.
///
/// All overlays use the same vocabulary of positions; keeping the mapping in
/// one place stops the copies from drifting (issue 16). The font size stays in
/// each overlay because the three use different scales.
class OverlayPosition {
  const OverlayPosition._(
    this.alignment,
    this.padding,
    this.crossAxisAlignment,
  );

  /// Distance kept between the overlay and the screen edge.
  static const double _margin = 24;

  static const bottomLeft = OverlayPosition._(
    Alignment.bottomLeft,
    EdgeInsets.only(left: _margin, bottom: _margin),
    CrossAxisAlignment.start,
  );

  static const bottomRight = OverlayPosition._(
    Alignment.bottomRight,
    EdgeInsets.only(right: _margin, bottom: _margin),
    CrossAxisAlignment.end,
  );

  static const topLeft = OverlayPosition._(
    Alignment.topLeft,
    EdgeInsets.only(left: _margin, top: _margin),
    CrossAxisAlignment.start,
  );

  static const topRight = OverlayPosition._(
    Alignment.topRight,
    EdgeInsets.only(right: _margin, top: _margin),
    CrossAxisAlignment.end,
  );

  final Alignment alignment;
  final EdgeInsets padding;
  final CrossAxisAlignment crossAxisAlignment;

  /// The placement for the 'bottomLeft'..'topRight' vocabulary used by the
  /// config, defaulting to bottomRight for unknown values.
  static OverlayPosition of(String position) => switch (position) {
    'bottomLeft' => bottomLeft,
    'topRight' => topRight,
    'topLeft' => topLeft,
    _ => bottomRight,
  };
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Caps the width of a dropdown in a settings row.
///
/// A control that stretches across a wide tablet looks disconnected from its
/// label, and a narrow phone row must not hand most of its width to the
/// control either, so the width never exceeds a share of the screen.
Widget boundedDropdown(BuildContext context, Widget child) {
  final maxWidth = math.min(170.0, MediaQuery.sizeOf(context).width * 0.4);

  return ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: child,
  );
}

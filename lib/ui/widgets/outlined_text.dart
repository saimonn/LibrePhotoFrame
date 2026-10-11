import 'package:flutter/material.dart';

class OutlinedText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color outlineColor;
  final double outlineWidth;
  final TextOverflow? overflow;
  final int? maxLines;

  const OutlinedText(
    this.text, {
    super.key,
    required this.style,
    this.outlineColor = Colors.black,
    this.outlineWidth = 2.0,
    this.overflow,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = outlineWidth
              ..color = outlineColor,
          ),
          overflow: overflow,
          maxLines: maxLines,
        ),
        Text(
          text,
          style: style.copyWith(color: style.color ?? Colors.white),
          overflow: overflow,
          maxLines: maxLines,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/ui/widgets/outlined_text.dart';

void main() {
  testWidgets('draws a stroked copy behind a filled copy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OutlinedText('Hello', style: TextStyle(fontSize: 20)),
      ),
    );

    final texts = tester.widgetList<Text>(find.byType(Text)).toList();
    expect(texts, hasLength(2));
    expect(texts[0].data, 'Hello');
    expect(texts[1].data, 'Hello');

    final stroke = texts[0].style!.foreground!;
    expect(stroke.style, PaintingStyle.stroke);
    expect(stroke.strokeWidth, 2.0);
    expect(stroke.color, Colors.black);

    expect(texts[1].style!.color, Colors.white);
  });

  testWidgets('honours the outline colour and width', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OutlinedText(
          'Hello',
          style: TextStyle(fontSize: 20, color: Colors.red),
          outlineColor: Colors.blue,
          outlineWidth: 4,
        ),
      ),
    );

    final texts = tester.widgetList<Text>(find.byType(Text)).toList();
    final stroke = texts[0].style!.foreground!;
    expect(stroke.color.toARGB32(), Colors.blue.toARGB32());
    expect(stroke.strokeWidth, 4.0);
    expect(texts[1].style!.color!.toARGB32(), Colors.red.toARGB32());
  });

  testWidgets('forwards overflow and maxLines to both copies', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OutlinedText(
          'A very long line',
          style: TextStyle(fontSize: 20),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );

    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      expect(text.overflow, TextOverflow.ellipsis);
      expect(text.maxLines, 1);
    }
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/ui/widgets/outlined_text.dart';

void main() {
  testWidgets('OutlinedText golden - basic', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: OutlinedText(
              'Hello World',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              outlineColor: Colors.black,
              outlineWidth: 2.5,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await expectLater(
      find.byType(OutlinedText),
      matchesGoldenFile('goldens/outlined_text_basic.png'),
    );
  });
}

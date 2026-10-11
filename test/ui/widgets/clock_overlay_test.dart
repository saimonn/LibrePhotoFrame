import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:libre_photo_frame/l10n/app_localizations.dart';
import 'package:libre_photo_frame/ui/widgets/clock_overlay.dart';
import 'package:libre_photo_frame/ui/widgets/outlined_text.dart';

void main() {
  Future<void> pumpClock(
    WidgetTester tester, {
    String size = 'medium',
    String position = 'bottomRight',
    String format = 'auto',
    bool enhancedContrast = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: ClockOverlay(
            size: size,
            position: position,
            format: format,
            enhancedContrast: enhancedContrast,
          ),
        ),
      ),
    );
  }

  // The clock wakes at the next minute boundary, so the overlay must be removed
  // before the test ends or its timer stays pending.
  Future<void> disposeClock(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  Text clockText(WidgetTester tester) {
    return tester.widget<Text>(
      find.descendant(
        of: find.byType(ClockOverlay),
        matching: find.byType(Text),
      ),
    );
  }

  testWidgets('formats the time on the requested 24-hour clock', (tester) async {
    await pumpClock(tester, format: '24');

    expect(clockText(tester).data, matches(RegExp(r'^\d{2}:\d{2}$')));

    await disposeClock(tester);
  });

  testWidgets('formats the time on the requested 12-hour clock', (tester) async {
    await pumpClock(tester, format: '12');

    expect(clockText(tester).data, matches(RegExp(r'^\d{1,2}:\d{2} [AP]M$')));

    await disposeClock(tester);
  });

  testWidgets('sizes the text with the chosen size', (tester) async {
    await pumpClock(tester, size: 'small');
    expect(clockText(tester).style!.fontSize, 32);
    await disposeClock(tester);

    await pumpClock(tester, size: 'medium');
    expect(clockText(tester).style!.fontSize, 48);
    await disposeClock(tester);

    await pumpClock(tester, size: 'large');
    expect(clockText(tester).style!.fontSize, 72);
    await disposeClock(tester);
  });

  testWidgets('unknown sizes fall back to medium', (tester) async {
    await pumpClock(tester, size: 'huge');
    expect(clockText(tester).style!.fontSize, 48);
    await disposeClock(tester);
  });

  testWidgets('places the overlay in the requested corner', (tester) async {
    await pumpClock(tester, position: 'topLeft');

    final align = tester.widget<Align>(
      find.descendant(of: find.byType(ClockOverlay), matching: find.byType(Align)),
    );
    final padding = tester.widget<Padding>(
      find.descendant(of: find.byType(ClockOverlay), matching: find.byType(Padding)),
    );
    expect(align.alignment, Alignment.topLeft);
    expect(padding.padding, const EdgeInsets.only(left: 24, top: 24));

    await disposeClock(tester);
  });

  testWidgets('uses outlined text for enhanced contrast', (tester) async {
    await pumpClock(tester, enhancedContrast: true);

    expect(find.byType(OutlinedText), findsOneWidget);
    // The outlined text paints a stroke and a fill copy of the same string.
    expect(find.byType(Text), findsNWidgets(2));

    await disposeClock(tester);
  });
}

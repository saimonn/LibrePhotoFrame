import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/domain/services/filename_date.dart';

/// Issue 20: a synced photo (Syncthing) keeps the sync time as its timestamps
/// and may have no EXIF at all (WhatsApp strips it), so the date has to be read
/// back from the file name the app is about to show.
void main() {
  group('FilenameDate.parse', () {
    test('reads the date-only WhatsApp name', () {
      expect(FilenameDate.parse('IMG-20261224-WA0001.jpg'), DateTime(2026, 12, 24));
    });

    test('reads the video variant', () {
      expect(FilenameDate.parse('VID-20261224-WA0001.mp4'), DateTime(2026, 12, 24));
    });

    test('reads a camera name down to the second', () {
      expect(
        FilenameDate.parse('IMG_20261224_133700.jpg'),
        DateTime(2026, 12, 24, 13, 37),
      );
    });

    test('reads a name with hour and minute only', () {
      expect(
        FilenameDate.parse('IMG_20261224_1337.jpg'),
        DateTime(2026, 12, 24, 13, 37),
      );
    });

    test('ignores the pixel counter of a Pixel name', () {
      expect(
        FilenameDate.parse('PXL_20261224_133700123.jpg'),
        DateTime(2026, 12, 24, 13, 37),
      );
    });

    test('reads a screenshot name', () {
      expect(
        FilenameDate.parse('Screenshot_20261224-133700.png'),
        DateTime(2026, 12, 24, 13, 37),
      );
    });

    test('reads a compact name without separators', () {
      expect(
        FilenameDate.parse('20261224133700.jpg'),
        DateTime(2026, 12, 24, 13, 37),
      );
    });

    test('reads a separated date and time', () {
      expect(
        FilenameDate.parse('2026-12-24_13-37-00.jpg'),
        DateTime(2026, 12, 24, 13, 37),
      );
    });

    test('reads a separated date without time', () {
      expect(FilenameDate.parse('2026-12-24.jpg'), DateTime(2026, 12, 24));
    });

    test('reads the name, not the folder, of a full path', () {
      expect(
        FilenameDate.parse('/storage/emulated/0/kiosk01/IMG-20261224-WA0001.jpg'),
        DateTime(2026, 12, 24),
      );
      expect(FilenameDate.parse('/2020/01/photo.jpg'), isNull);
    });

    test('returns null when the name carries no date', () {
      expect(FilenameDate.parse('photo.jpg'), isNull);
      expect(FilenameDate.parse('123456789.jpg'), isNull);
    });

    test('rejects an impossible month', () {
      expect(FilenameDate.parse('IMG-20261324-WA0001.jpg'), isNull);
    });

    test('rejects an impossible day', () {
      expect(FilenameDate.parse('20260230.jpg'), isNull);
    });

    test('rejects an out-of-range year', () {
      expect(FilenameDate.parse('18991231.jpg'), isNull);
    });

    test('keeps the date and drops an impossible time', () {
      expect(
        FilenameDate.parse('IMG_20261224_253700.jpg'),
        DateTime(2026, 12, 24),
      );
      expect(
        FilenameDate.parse('IMG_20261224_136000.jpg'),
        DateTime(2026, 12, 24),
      );
    });
  });
}

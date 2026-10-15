import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/ui/screens/settings/slide_duration_scale.dart';

void main() {
  group('SlideDurationScale.durations', () {
    test('is sorted, strictly increasing and within 5s..24h', () {
      expect(SlideDurationScale.durations.first, 5);
      expect(SlideDurationScale.durations.last, 86400);
      for (var i = 1; i < SlideDurationScale.durations.length; i++) {
        expect(
          SlideDurationScale.durations[i],
          greaterThan(SlideDurationScale.durations[i - 1]),
        );
      }
    });

    test('contains the expected anchors', () {
      expect(SlideDurationScale.durations, contains(45));
      expect(SlideDurationScale.durations, contains(60));
      expect(SlideDurationScale.durations, contains(2700));
      expect(SlideDurationScale.durations, contains(3600));
      expect(SlideDurationScale.durations, contains(86400));
    });
  });

  group('SlideDurationScale.secondsAt', () {
    test('maps every step to its duration', () {
      for (var i = 0; i < SlideDurationScale.durations.length; i++) {
        expect(SlideDurationScale.secondsAt(i), SlideDurationScale.durations[i]);
      }
    });

    test('clamps below and above the track', () {
      expect(SlideDurationScale.secondsAt(-10), 5);
      expect(SlideDurationScale.secondsAt(SlideDurationScale.lastStep + 10), 86400);
    });
  });

  group('SlideDurationScale.stepForSeconds', () {
    test('returns the exact step for a listed duration', () {
      for (var i = 0; i < SlideDurationScale.durations.length; i++) {
        expect(SlideDurationScale.stepForSeconds(SlideDurationScale.durations[i]), i);
      }
    });

    test('snaps to the nearest duration', () {
      expect(SlideDurationScale.secondsAt(SlideDurationScale.stepForSeconds(7)), 5);
      expect(SlideDurationScale.secondsAt(SlideDurationScale.stepForSeconds(8)), 10);
      expect(SlideDurationScale.secondsAt(SlideDurationScale.stepForSeconds(100)), 120);
      expect(SlideDurationScale.secondsAt(SlideDurationScale.stepForSeconds(3000)), 2700);
      expect(SlideDurationScale.secondsAt(SlideDurationScale.stepForSeconds(5000)), 3600);
    });

    test('clamps out-of-range durations to the track ends', () {
      expect(SlideDurationScale.stepForSeconds(0), 0);
      expect(SlideDurationScale.stepForSeconds(-100), 0);
      expect(SlideDurationScale.stepForSeconds(1000000), SlideDurationScale.lastStep);
    });

    test('round-trips every step', () {
      for (var i = 0; i <= SlideDurationScale.lastStep; i++) {
        final seconds = SlideDurationScale.secondsAt(i);
        expect(SlideDurationScale.stepForSeconds(seconds), i);
      }
    });
  });
}

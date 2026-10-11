import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/domain/interfaces/display_controller.dart';
import 'package:libre_photo_frame/infrastructure/services/native_display_controller.dart';

/// The unit tests run on a desktop host, where the controller takes its
/// brightness-free fallback path. The Android paths are covered by the
/// on-device job.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeDisplayController', () {
    late NativeDisplayController controller;

    setUp(() {
      controller = NativeDisplayController();
    });

    tearDown(() => controller.dispose());

    test('reports no native screen-off support off Android', () {
      expect(controller.supportsScreenOff, isFalse);
      expect(controller.isDeviceAdminEnabled, isFalse);
      expect(controller.currentMode, DisplayMode.normal);
    });

    test('clamps the dimmed brightness to the valid range', () {
      controller.dimmedBrightness = -1;
      expect(controller.dimmedBrightness, 0.0);

      controller.dimmedBrightness = 2;
      expect(controller.dimmedBrightness, 1.0);
    });

    test('switches between all three modes', () async {
      expect((await controller.setMode(DisplayMode.dimmed)).success, isTrue);
      expect(controller.currentMode, DisplayMode.dimmed);

      expect((await controller.setMode(DisplayMode.off)).success, isTrue);
      expect(controller.currentMode, DisplayMode.off);

      expect((await controller.setMode(DisplayMode.normal)).success, isTrue);
      expect(controller.currentMode, DisplayMode.normal);
    });

    test('sets an explicit brightness and maps it to a mode', () async {
      final dim = await controller.setBrightness(0.05);
      expect(dim.success, isTrue);
      expect(dim.actualBrightness, 0.05);
      expect(controller.currentMode, DisplayMode.dimmed);

      final bright = await controller.setBrightness(0.8);
      expect(bright.actualBrightness, 0.8);
      expect(controller.currentMode, DisplayMode.normal);
    });

    test('brightness zero turns the screen off', () async {
      final result = await controller.setBrightness(0);

      expect(result.success, isTrue);
      expect(controller.currentMode, DisplayMode.off);
    });

    test('getCurrentBrightness falls back to one off Android', () async {
      expect(await controller.getCurrentBrightness(), 1.0);
    });

    test('sleepUntil and wakeNow go through setMode', () async {
      final result = await controller.sleepUntil(DateTime(2026, 1, 1, 7));
      expect(result.success, isTrue);
      expect(controller.currentMode, DisplayMode.off);

      await controller.wakeNow();
      expect(controller.currentMode, DisplayMode.normal);
    });

    test('refreshing or requesting device admin stays disabled off Android',
        () async {
      await controller.refreshDeviceAdminStatus();
      expect(controller.isDeviceAdminEnabled, isFalse);

      await controller.requestDeviceAdmin();
      expect(controller.isDeviceAdminEnabled, isFalse);
    });
  });
}

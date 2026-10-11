import 'package:flutter_test/flutter_test.dart';
import 'package:libre_photo_frame/domain/interfaces/display_controller.dart';
import 'package:libre_photo_frame/infrastructure/services/display_schedule_service.dart';

class FakeDisplayController implements DisplayController {
  final List<DisplayMode> setModeCalls = [];
  bool disposed = false;

  DisplayMode _mode = DisplayMode.normal;
  double _dimmedBrightness = 0.1;

  @override
  Future<DisplayControlResult> setMode(DisplayMode mode) async {
    setModeCalls.add(mode);
    _mode = mode;
    return const DisplayControlResult.success();
  }

  @override
  Future<DisplayControlResult> setBrightness(double brightness) async {
    return DisplayControlResult.success(actualBrightness: brightness);
  }

  @override
  Future<double> getCurrentBrightness() async => 0.5;

  @override
  double get dimmedBrightness => _dimmedBrightness;

  @override
  set dimmedBrightness(double value) => _dimmedBrightness = value;

  @override
  bool get supportsScreenOff => true;

  @override
  DisplayMode get currentMode => _mode;

  @override
  void dispose() => disposed = true;
}

const daytime = DisplaySchedule(
  startTime: TimeOfDay(hour: 9, minute: 0),
  endTime: TimeOfDay(hour: 17, minute: 0),
  mode: DisplayMode.dimmed,
);

const overnight = DisplaySchedule(
  startTime: TimeOfDay(hour: 22, minute: 0),
  endTime: TimeOfDay(hour: 7, minute: 0),
  mode: DisplayMode.off,
);

DateTime at(int hour, [int minute = 0]) =>
    DateTime(2026, 1, 1, hour, minute);

void main() {
  group('DisplaySchedule.isActiveAt', () {
    test('a daytime window includes its start and excludes its end', () {
      expect(daytime.isActiveAt(at(9, 0)), isTrue);
      expect(daytime.isActiveAt(at(12, 0)), isTrue);
      expect(daytime.isActiveAt(at(16, 59)), isTrue);
      expect(daytime.isActiveAt(at(8, 59)), isFalse);
      expect(daytime.isActiveAt(at(17, 0)), isFalse);
      expect(daytime.isActiveAt(at(23, 0)), isFalse);
    });

    test('an overnight window spans midnight', () {
      expect(overnight.isActiveAt(at(22, 0)), isTrue);
      expect(overnight.isActiveAt(at(23, 30)), isTrue);
      expect(overnight.isActiveAt(at(0, 0)), isTrue);
      expect(overnight.isActiveAt(at(6, 59)), isTrue);
      expect(overnight.isActiveAt(at(7, 0)), isFalse);
      expect(overnight.isActiveAt(at(21, 59)), isFalse);
      expect(overnight.isActiveAt(at(12, 0)), isFalse);
    });

    test('a disabled schedule is never active', () {
      final disabled = daytime.copyWith(enabled: false);
      expect(disabled.isActiveAt(at(12, 0)), isFalse);
      expect(disabled.isActiveAt(at(23, 0)), isFalse);
    });

    test('a zero-length window is never active', () {
      const empty = DisplaySchedule(
        startTime: TimeOfDay(hour: 12, minute: 0),
        endTime: TimeOfDay(hour: 12, minute: 0),
        mode: DisplayMode.dimmed,
      );
      expect(empty.isActiveAt(at(12, 0)), isFalse);
      expect(empty.isActiveAt(at(12, 1)), isFalse);
      expect(empty.isActiveAt(at(11, 59)), isFalse);
    });
  });

  group('DisplaySchedule.nextTransitionFrom', () {
    test('returns a year away while disabled', () {
      final now = at(12, 0);
      final disabled = daytime.copyWith(enabled: false);
      expect(disabled.nextTransitionFrom(now), now.add(const Duration(days: 365)));
    });

    test('an active daytime schedule ends today', () {
      expect(daytime.nextTransitionFrom(at(10, 0)), at(17, 0));
    });

    test('an inactive schedule before its start begins today', () {
      expect(daytime.nextTransitionFrom(at(8, 0)), at(9, 0));
    });

    test('an inactive schedule after its start begins tomorrow', () {
      expect(
        daytime.nextTransitionFrom(at(18, 0)),
        DateTime(2026, 1, 2, 9, 0),
      );
    });

    test('an active overnight schedule ends tomorrow morning', () {
      expect(
        overnight.nextTransitionFrom(at(23, 0)),
        DateTime(2026, 1, 2, 7, 0),
      );
    });

    test('an overnight schedule just before its end ends today', () {
      expect(overnight.nextTransitionFrom(at(6, 0)), at(7, 0));
    });

    test('an inactive overnight schedule begins tonight', () {
      expect(overnight.nextTransitionFrom(at(12, 0)), at(22, 0));
    });
  });

  group('DisplaySchedule serialization', () {
    test('toJson writes the fields the config stores', () {
      expect(daytime.toJson(), {
        'startHour': 9,
        'startMinute': 0,
        'endHour': 17,
        'endMinute': 0,
        'mode': 'dimmed',
        'enabled': true,
      });
    });

    test('round-trips through toJson and fromJson', () {
      final restored = DisplaySchedule.fromJson(daytime.toJson());
      expect(restored.startTime, daytime.startTime);
      expect(restored.endTime, daytime.endTime);
      expect(restored.mode, daytime.mode);
      expect(restored.enabled, daytime.enabled);
    });

    test('fromJson falls back to the night defaults', () {
      final schedule = DisplaySchedule.fromJson(const {});
      expect(schedule.startTime, const TimeOfDay(hour: 22, minute: 0));
      expect(schedule.endTime, const TimeOfDay(hour: 7, minute: 0));
      expect(schedule.mode, DisplayMode.off);
      expect(schedule.enabled, isFalse);
    });

    test('fromJson maps an unknown mode to off', () {
      final schedule = DisplaySchedule.fromJson(const {'mode': 'nope'});
      expect(schedule.mode, DisplayMode.off);
    });
  });

  group('DisplaySchedule helpers', () {
    test('copyWith replaces only the provided fields', () {
      final changed = daytime.copyWith(endTime: const TimeOfDay(hour: 20, minute: 30));
      expect(changed.startTime, daytime.startTime);
      expect(changed.endTime, const TimeOfDay(hour: 20, minute: 30));
      expect(changed.mode, daytime.mode);
      expect(changed.enabled, isTrue);
    });

    test('copyWith without arguments keeps every field', () {
      final copy = daytime.copyWith();
      expect(copy.startTime, daytime.startTime);
      expect(copy.endTime, daytime.endTime);
      expect(copy.mode, daytime.mode);
      expect(copy.enabled, daytime.enabled);
    });

    test('nightMode uses 22:00 - 07:00 off by default', () {
      final schedule = DisplaySchedule.nightMode();
      expect(schedule.startTime, const TimeOfDay(hour: 22, minute: 0));
      expect(schedule.endTime, const TimeOfDay(hour: 7, minute: 0));
      expect(schedule.mode, DisplayMode.off);
      expect(schedule.enabled, isTrue);
    });

    test('nightMode honours explicit parameters', () {
      final schedule = DisplaySchedule.nightMode(
        startTime: const TimeOfDay(hour: 21, minute: 15),
        endTime: const TimeOfDay(hour: 6, minute: 45),
        mode: DisplayMode.dimmed,
        enabled: false,
      );
      expect(schedule.startTime, const TimeOfDay(hour: 21, minute: 15));
      expect(schedule.endTime, const TimeOfDay(hour: 6, minute: 45));
      expect(schedule.mode, DisplayMode.dimmed);
      expect(schedule.enabled, isFalse);
    });
  });

  group('TimeOfDay', () {
    test('toString pads single digits', () {
      expect(const TimeOfDay(hour: 9, minute: 5).toString(), '09:05');
      expect(const TimeOfDay(hour: 22, minute: 45).toString(), '22:45');
    });

    test('equality and hashCode use hour and minute', () {
      expect(
        const TimeOfDay(hour: 9, minute: 5),
        const TimeOfDay(hour: 9, minute: 5),
      );
      expect(
        const TimeOfDay(hour: 9, minute: 5).hashCode,
        const TimeOfDay(hour: 9, minute: 5).hashCode,
      );
      expect(
        const TimeOfDay(hour: 9, minute: 5),
        isNot(const TimeOfDay(hour: 9, minute: 6)),
      );
    });
  });

  group('DisplayScheduleService', () {
    late FakeDisplayController controller;
    late DisplayScheduleService service;
    var now = at(10, 0);

    setUp(() {
      now = at(10, 0);
      controller = FakeDisplayController();
      service = DisplayScheduleService(
        displayController: controller,
        nowProvider: () => now,
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('applies an active schedule immediately', () async {
      await service.setSchedule(daytime);
      expect(controller.setModeCalls, [DisplayMode.dimmed]);
      expect(service.isScheduleActive, isTrue);
      expect(service.schedule, same(daytime));
      expect(service.displayController, same(controller));
    });

    test('leaves the display alone for an inactive schedule', () async {
      now = at(20, 0);
      await service.setSchedule(daytime);
      expect(controller.setModeCalls, isEmpty);
      expect(service.isScheduleActive, isFalse);
    });

    test('a disabled schedule never activates', () async {
      await service.setSchedule(daytime.copyWith(enabled: false));
      expect(controller.setModeCalls, isEmpty);
      expect(service.isScheduleActive, isFalse);
    });

    test('clearing an active schedule returns the display to normal', () async {
      await service.setSchedule(daytime);
      await service.setSchedule(null);
      expect(controller.setModeCalls, [DisplayMode.dimmed, DisplayMode.normal]);
      expect(service.isScheduleActive, isFalse);
      expect(service.schedule, isNull);
    });

    test('checkNow reacts when the time enters and leaves the window', () async {
      now = at(8, 0);
      await service.setSchedule(daytime);
      expect(controller.setModeCalls, isEmpty);

      now = at(12, 0);
      await service.checkNow();
      expect(controller.setModeCalls, [DisplayMode.dimmed]);
      expect(service.isScheduleActive, isTrue);

      now = at(18, 0);
      await service.checkNow();
      expect(controller.setModeCalls, [DisplayMode.dimmed, DisplayMode.normal]);
      expect(service.isScheduleActive, isFalse);
    });

    test('the state stream reports activation and deactivation', () async {
      final states = <bool>[];
      final subscription = service.onScheduleStateChanged.listen(states.add);
      addTearDown(subscription.cancel);

      now = at(8, 0);
      await service.setSchedule(daytime);
      now = at(12, 0);
      await service.checkNow();
      now = at(18, 0);
      await service.checkNow();
      await Future<void>.delayed(Duration.zero);

      expect(states, [true, false]);
    });

    test('overrideMode cancels scheduling until resumeSchedule', () async {
      await service.setSchedule(daytime);
      expect(controller.setModeCalls, [DisplayMode.dimmed]);

      await service.overrideMode(DisplayMode.normal);
      expect(controller.setModeCalls, [DisplayMode.dimmed, DisplayMode.normal]);
      expect(service.isScheduleActive, isTrue);

      now = at(12, 0);
      await service.resumeSchedule();
      expect(controller.setModeCalls, [DisplayMode.dimmed, DisplayMode.normal]);
    });

    test('dispose releases the controller and closes the stream', () async {
      await service.setSchedule(daytime);

      var closed = false;
      final subscription =
          service.onScheduleStateChanged.listen((_) {}, onDone: () => closed = true);

      service.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(controller.disposed, isTrue);
      expect(closed, isTrue);
      await subscription.cancel();
    });
  });
}

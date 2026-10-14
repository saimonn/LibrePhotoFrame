import 'dart:async';

/// Encapsulates slideshow timer start/pause/reschedule/stop logic.
class SlideTimerController {
  Timer? _timer;
  Duration _duration;
  final void Function() _onTick;

  SlideTimerController({
    required Duration initialDuration,
    required void Function() onTick,
  })  : _duration = initialDuration,
        _onTick = onTick;

  bool get isActive => _timer?.isActive ?? false;

  Duration get duration => _duration;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(_duration, (_) => _onTick());
  }

  void pause() {
    _timer?.cancel();
  }

  void resume() {
    if (!isActive) {
      start();
    }
  }

  void stop() {
    _timer?.cancel();
  }

  void reschedule(Duration duration) {
    _duration = duration;
    if (isActive) {
      start();
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

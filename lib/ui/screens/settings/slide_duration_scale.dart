/// Discrete scale of slide durations, from 5 seconds to 24 hours.
///
/// The steps grow roughly geometrically: fine near the short end and coarse
/// near the long end, so the whole range stays reachable on a single slider
/// without hundredths of seconds in between.
class SlideDurationScale {
  SlideDurationScale._();

  /// One entry per slider position, in seconds.
  static const List<int> durations = <int>[
    5, 10, 15, 30, 45, // seconds
    60, 120, 180, 300, 600, 900, 1200, 1800, 2700, // 1 to 45 minutes
    3600, 7200, 10800, 14400, 21600, 28800, 43200, 86400, // 1 to 24 hours
  ];

  /// Number of divisions on the slider (gaps between two values).
  static int get lastStep => durations.length - 1;

  /// Duration in seconds for a slider position, clamped to the track.
  static int secondsAt(int step) => durations[step.clamp(0, lastStep)];

  /// Nearest slider position for a duration in seconds. Ties pick the
  /// shorter duration.
  static int stepForSeconds(int seconds) {
    var best = 0;
    for (var i = 1; i < durations.length; i++) {
      if ((durations[i] - seconds).abs() < (durations[best] - seconds).abs()) {
        best = i;
      }
    }
    return best;
  }
}
